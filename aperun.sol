// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract ApeRun is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcludedInReward;
    address[] public _excludedInReward;

    mapping (address => uint256) private lastTimeBuy;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tRewardTotal;

    string private _name = "APERUN";
    string private _symbol = "APERUN";
    uint8 private _decimals = 18;
    
    uint256 public _distributionFee = 3;
    uint256 private _previousDistributionFee = _distributionFee;
    
    uint256 public _burnFee = 3;
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _marketingFee = 5;
    uint256 private _previousMarketingFee = _marketingFee;

    address public burnWallet = 0x000000000000000000000000000000000000dEaD;
    address public marketingWallet = 0x8015a6D2c040924F6329B2C11a12ce4c83558aA0;


    event TransferBothExcluded(address indexed from, address indexed to, uint256 value);
    event TransferStandard(address indexed from, address indexed to, uint256 value);
    event TransferFromExcluded(address indexed from, address indexed to, uint256 value);
    event TransferToExcluded(address indexed from, address indexed to, uint256 value);
    event TransferMarketingToken(address indexed from, address indexed to, uint256 value);
    event TransferBurnToken(address indexed from, address indexed to, uint256 value);
    event DistributeToken(uint256 rvalue,uint256 tvalue);

    constructor ()  {

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        excludeFromReward(burnWallet);

        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedInReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedInReward[account];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function totalRewards() public view returns (uint256) {
        return _tRewardTotal;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedInReward[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedInReward[account] = true;
       _excludedInReward.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedInReward[account], "Account is already excluded");
        for (uint256 i = 0; i <_excludedInReward.length; i++) {
            if (_excludedInReward[i] == account) {
               _excludedInReward[i] =_excludedInReward[_excludedInReward.length - 1];
                _tOwned[account] = 0;
                _isExcludedInReward[account] = false;
               _excludedInReward.pop();
                break;
            }
        }
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
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

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _distributionToAllHolder(uint256 rDistribution, uint256 tDistribution) private {
        _rTotal = _rTotal.sub(rDistribution);
        _tRewardTotal = _tRewardTotal.add(tDistribution);
        emit DistributeToken(_rTotal,_tRewardTotal);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution) = _getRValues(tAmount, tDistribution, tMarketingAndBurn, _getRate());
        return (rAmount, rTransferAmount, rDistribution, tTransferAmount, tDistribution, tMarketingAndBurn);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tDistribution = calculateDistributionFee(tAmount);
        uint256 tMarketingAndBurn = calculateBurnAndMarketingFee(tAmount);
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

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i <_excludedInReward.length; i++) {
            if (_rOwned[_excludedInReward[i]] > rSupply || _tOwned[_excludedInReward[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excludedInReward[i]]);
            tSupply = tSupply.sub(_tOwned[_excludedInReward[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeMarketingAndBurnToken(uint256 tMarketingAndBurn, address sender) private {
        if(_marketingFee + _burnFee > 0){
            uint256 tMarketing = tMarketingAndBurn.mul(_marketingFee).div(_marketingFee + _burnFee);
            uint256 tBurn = tMarketingAndBurn.sub(tMarketing);

            uint256 currentRate =  _getRate();

            uint256 rBurn = tBurn.mul(currentRate);
            _rOwned[burnWallet] = _rOwned[burnWallet].add(rBurn);
            if(_isExcludedInReward[burnWallet])
                _tOwned[burnWallet] = _tOwned[burnWallet].add(tBurn);
            emit TransferBurnToken(sender, burnWallet, tBurn);

            uint256 rMarketing = tMarketing.mul(currentRate);
            _rOwned[marketingWallet] = _rOwned[marketingWallet].add(rMarketing);
            if(_isExcludedInReward[marketingWallet])
                _tOwned[marketingWallet] = _tOwned[marketingWallet].add(tMarketing);
            emit TransferMarketingToken(sender, marketingWallet, tMarketing);
        }
    }
    
    function calculateDistributionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_distributionFee).div(
            10**2
        );
    }

    function calculateBurnAndMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee + _marketingFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_distributionFee == 0 && _burnFee == 0 && _marketingFee == 0) return;
        
        _previousDistributionFee = _distributionFee;
        _previousBurnFee = _burnFee;
        _previousMarketingFee = _marketingFee;
        
        _distributionFee = 0;
        _burnFee = 0;
        _marketingFee = 0;
    }
    
    function restoreAllFee() private {
        _distributionFee = _previousDistributionFee;
        _burnFee = _previousBurnFee;
        _marketingFee = _previousMarketingFee;
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcludedInReward[sender] && !_isExcludedInReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedInReward[sender] && _isExcludedInReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedInReward[sender] && !_isExcludedInReward[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedInReward[sender] && _isExcludedInReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeMarketingAndBurnToken(tMarketingAndBurn, sender);
        _distributionToAllHolder(rDistribution, tDistribution);
        emit TransferStandard(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeMarketingAndBurnToken(tMarketingAndBurn, sender);
        _distributionToAllHolder(rDistribution, tDistribution);
        emit TransferToExcluded(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeMarketingAndBurnToken(tMarketingAndBurn, sender);
        _distributionToAllHolder(rDistribution, tDistribution);
        emit TransferFromExcluded(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeMarketingAndBurnToken(tMarketingAndBurn, sender);
        _distributionToAllHolder(rDistribution, tDistribution);
        emit TransferBothExcluded(sender, recipient, tTransferAmount);
    }
}