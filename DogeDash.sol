// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract DogeDash is Ownable,IERC20 {

    using SafeMath for uint256;
    using Address for address;

    mapping (address => mapping (address => uint256)) _allowances;
    mapping(address => uint256) public _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;

    mapping (address => bool) public isExcludedFromFee;

    mapping (address => bool) private _isExcludedFromReward;
    address[] public _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10**11 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tRewardTotal;

    string public name = "DogeDash";
    string public symbol = "DogeDash";
    uint8 public decimals = 18;

    uint256 public _distributionFee = 3;
    uint256 private _previousDistributionFee = _distributionFee;
    
    uint256 public _burnFee = 3;
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _marketingFee = 3;
    uint256 private _previousMarketingFee = _marketingFee;

    address public burnWallet = 0x000000000000000000000000000000000000dEaD;
    address public marketingWallet;

    event Log(string name);
    event TransferBothExcluded(address indexed from, address indexed to, uint256 value);
    event TransferStandard(address indexed from, address indexed to, uint256 value);
    event TransferFromExcluded(address indexed from, address indexed to, uint256 value);
    event TransferToExcluded(address indexed from, address indexed to, uint256 value);
    event TransferMarketing(address indexed from, address indexed to, uint256 value);
    event TransferBurn(address indexed from, address indexed to, uint256 value);
    event GetValues(uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn);
    event DistributionHolder(uint256 rvalue, uint256 tvalue);

    constructor(){
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        
        marketingWallet = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;

        excludeFromReward(burnWallet);
        
        _reflectionBalance[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function totalSupply() public view override returns (uint256){
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256 balance) {
       if (_isExcludedFromReward[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function transfer(address to, uint256 amount) public override virtual returns (bool) {
        _transfer(msg.sender, to,  amount);
        return true;
    }

    function ShowtransferVal(uint256 amount) public view returns(bool){
        return _tokenBalance[_msgSender()]>= amount && amount > 0;
    }

    function allowance(address owner, address spender) public view  override returns (uint256){
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool success) {
       _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address spenderOwner, address recipient, uint256 amount) public override virtual returns (bool) {
        require(_allowances[spenderOwner][_msgSender()] >= amount,"Amount is more then approve amount"); // Check allowance amount
        _transfer(spenderOwner,recipient,amount);
               
        _approve(spenderOwner,_msgSender(),_allowances[spenderOwner][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        require(addedValue > 0, "Transfer amount must be greater than zero");  // Don't allow 0Amount transfer
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(_allowances[_msgSender()][spender] > subtractedValue && subtractedValue > 0,"Amount is not enough");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }
    
    function totalRewards() public view returns (uint256) {
        return _tRewardTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(_reflectionBalance[account]);
        }
        _isExcludedFromReward[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenBalance[account] = 0;
                _isExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function excludeFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }

    function setDistributionFeePercent(uint256 distributionFee) external onlyOwner() {
        _distributionFee = distributionFee;
    }
    
    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        _marketingFee = marketingFee;
    }

    function updateMarketingWallet(address account) public onlyOwner {
        marketingWallet = account;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _showRefandTotBal(uint256 val) public view returns(uint256,uint256){

        return( _reflectionBalance[_excluded[val]],_tokenBalance[_excluded[val]]);
    }

    function _getCurrentSupply() public view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectionBalance[_excluded[i]] > rSupply || _tokenBalance[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_reflectionBalance[_excluded[i]]);
            tSupply = tSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply); 
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from,address to, uint256 amount) private {
        require(from != address(0),"ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero"); // Don't allow 0Amount transfer
       
        bool takeFee = true;
        if(isExcludedFromFee[from] || isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee);
    }

    function _getValues(uint256 tAmount) private  returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution) = _getRValues(tAmount, tDistribution, tMarketingAndBurn, _getRate());
        emit GetValues(rAmount, rTransferAmount, rDistribution, tTransferAmount, tDistribution, tMarketingAndBurn);
        return (rAmount, rTransferAmount, rDistribution, tTransferAmount, tDistribution, tMarketingAndBurn);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tDistribution = tAmount.mul(_distributionFee).div(100); 
        uint256 tMarketingAndBurn = tAmount.mul(_burnFee + _marketingFee).div(10**2); 
        uint256 tTransferAmount = tAmount.sub(tDistribution).sub(tMarketingAndBurn); 
        return (tTransferAmount, tDistribution, tMarketingAndBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tDistribution, uint256 tMarketingAndBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rDistribution = tDistribution.mul(currentRate);
        uint256 rMarketingAndBurn = tMarketingAndBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rDistribution).sub(rMarketingAndBurn);
        return (rAmount, rTransferAmount, rDistribution);
    }

    function _distributionToAllHolder(uint256 rDistribution, uint256 tDistribution) private {
        _rTotal = _rTotal.sub(rDistribution);
        _tRewardTotal = _tRewardTotal.add(tDistribution);
       emit DistributionHolder(rDistribution,_tRewardTotal);
    }

    function _takeMarketingAndBurnToken(uint256 tMarketingAndBurn, address sender) private {
        if(_marketingFee + _burnFee > 0){
            uint256 tMarketing = tMarketingAndBurn.mul(_marketingFee).div(_marketingFee + _burnFee);
            uint256 tBurn = tMarketingAndBurn.sub(tMarketing);

            uint256 currentRate =  _getRate();

            uint256 rBurn = tBurn.mul(currentRate);
            _reflectionBalance[burnWallet] = _reflectionBalance[burnWallet].add(rBurn);
            if(_isExcludedFromReward[burnWallet])
                _tokenBalance[burnWallet] = _tokenBalance[burnWallet].add(tBurn);
            emit TransferBurn(sender, burnWallet, tBurn);

            uint256 rMarketing = tMarketing.mul(currentRate);
            _reflectionBalance[marketingWallet] = _reflectionBalance[marketingWallet].add(rMarketing);
            if(_isExcludedFromReward[marketingWallet])
                _tokenBalance[marketingWallet] = _tokenBalance[marketingWallet].add(tMarketing);
            emit TransferMarketing(sender, marketingWallet, tMarketing);
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {

        if(!takeFee)
            removeAllFee();

        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]){
            _transferFromExcluded(sender,recipient,amount);
        }
        else if(!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]){
            _transferToExcluded(sender,recipient,amount);
        } 
        else if(!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender,recipient,amount);
        } 
        else if(_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]){
            _transferBothExcluded(sender,recipient,amount);
        }
        else {
            _transferStandard(sender,recipient,amount);
        }

         if(!takeFee)
            restoreAllFee();
    }   

    function removeAllFee() private {
        if(_distributionFee == 0 && _burnFee == 0 && _marketingFee == 0) return;
        
        _previousDistributionFee = _distributionFee;
        _previousBurnFee = _burnFee;
        _previousMarketingFee = _marketingFee;
        
        _distributionFee = 0;
        _burnFee = 0;
        _marketingFee = 0;
        emit Log("removeAllFee");
    }
    
    function restoreAllFee() private {
        _distributionFee = _previousDistributionFee;
        _burnFee = _previousBurnFee;
        _marketingFee = _previousMarketingFee;
        emit Log("restoreAllFee   =====");
    }


    function _transferToExcluded(address sender,address recipient,uint256 amount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) =   _getValues(amount);
        
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(rAmount);
        _tokenBalance[recipient] = _tokenBalance[recipient].add(tTransferAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);           
        _takeMarketingAndBurnToken(tMarketingAndBurn, sender);
        _distributionToAllHolder(rDistribution, tDistribution);
        emit TransferToExcluded(sender, recipient, tTransferAmount);

    }

    function _transferFromExcluded(address sender,address recipient,uint256 amount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) =   _getValues(amount);
       
        _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(rAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);   
        _takeMarketingAndBurnToken(tMarketingAndBurn, sender);
        _distributionToAllHolder(rDistribution, tDistribution);
        emit TransferFromExcluded(sender, recipient, tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) = _getValues(tAmount);
        
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(rAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeMarketingAndBurnToken(tMarketingAndBurn, sender);
        _distributionToAllHolder(rDistribution, tDistribution);
        emit TransferStandard(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) = _getValues(tAmount);
        
        _tokenBalance[sender] = _tokenBalance[sender].sub(tAmount);
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(rAmount);
        _tokenBalance[recipient] = _tokenBalance[recipient].add(tTransferAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);        
        _takeMarketingAndBurnToken(tMarketingAndBurn, sender);
        _distributionToAllHolder(rDistribution, tDistribution);
        emit TransferBothExcluded(sender, recipient, tTransferAmount);
    }

    receive() external payable {}

}	

