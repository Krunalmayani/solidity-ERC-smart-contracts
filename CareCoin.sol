
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

pragma solidity ^0.8.7;

contract CareCoin is  Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) public _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10 * 10**9 * 10**9;
    uint256 public _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tRewardTotal;
    
    
    uint256 private _tFeeTotal;

    string private _name = "CareCoin";
    string private _symbol = "CARES";
    uint8 private _decimals = 9;

    uint256 private _distributionFee = 5;
    uint256 private _burnFee = 5;
    uint256 private _marketingFee = 5;

    address private burnWallet = 0x000000000000000000000000000000000000dEaD;
    address private marketingWallet = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;

    event Approval(address, address, uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        excludeFromReward(burnWallet);
        excludeFromReward(marketingWallet);
        excludeFromReward(_msgSender());
    }

    function showReflectionAmout(address _account) public view returns(uint256){
        return _rOwned[_account];
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function balanceOf(address account) public  view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return _tokenFromReflection(_rOwned[account]);
    }

    function totalRewards() public view returns (uint256) {
        return _tRewardTotal;
    }

    function excludeFromReward(address account) public onlyOwner{
        require(!_isExcluded[account],"Account is already excluded");
        if(_rOwned[account] > 0){
            _tOwned[account] = _tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function transfer(address recipient, uint256 amount) public  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address from,address to,uint256 amount) private   {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }   

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount);
    }

    function _tokenTransfer(address sender,address recipient, uint256 amount) private   {
        if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        }else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }
    
    function _getValues(uint256 tAmount) public view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tDistribution,uint256 tMarketingAndBurn,uint256 tTransferAmount) = _getTValues(tAmount);
        (uint256 rAmount,uint256 rTransferAmount,uint256 rDistribution) =  _getRValues(tAmount,tDistribution,tMarketingAndBurn,_getRate());

        return (rAmount, rTransferAmount, rDistribution, tTransferAmount, tDistribution, tMarketingAndBurn);
    }

    function _getTValues(uint256 tAmount) private view returns(uint256,uint256,uint256){
        uint256 tDistribution = calculateDistributionFee(tAmount);
        uint256 tMarketingAndBurn = calculateBurnAndMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tDistribution).sub(tMarketingAndBurn);
        return (tDistribution,tMarketingAndBurn,tTransferAmount);
    }

    function _getRValues(uint256 tAmount, uint256 tDistribution,uint256 tMarketingAndBurn,uint256 currentRate) private pure returns(uint256,uint256,uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rDistribution = tDistribution.mul(currentRate);
        uint256 rBurnAndMarketing = tMarketingAndBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rDistribution).sub(rBurnAndMarketing);
        return (rAmount, rTransferAmount, rDistribution);
    }

    function calculateDistributionFee(uint256 _amount) private view returns(uint256){
        return _amount.mul(_distributionFee).div(10**2);
    }

    function calculateBurnAndMarketingFee(uint256 _amount) private view returns(uint256){
        return _amount.mul(_marketingFee + _burnFee).div(10**2);
    }

    function _tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _getRate() public view  returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256,uint256){
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal; 

        for(uint256 i=0;i<_excluded.length;i++){
            if(_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply ) return (_rTotal,_tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);

        return (rSupply,tSupply);
    }

    function _distributionToAllHolder(uint256 rDistribution, uint256 tDistribution) private {
        _rTotal = _rTotal.sub(rDistribution);
        _tRewardTotal = _tRewardTotal.add(tDistribution);
    }

    function _takeMarketingAndBurnToken(uint256 tMarketingAndBurn, address sender) private{
        if(_marketingFee + _burnFee > 0){

            uint256 tMarketing = tMarketingAndBurn.mul(_marketingFee).div(_marketingFee + _burnFee);
            uint256 tBurn = tMarketingAndBurn.sub(tMarketing);

            uint256 currentRate =  _getRate();

            uint256 rBurn = tBurn.mul(currentRate);
            _rOwned[burnWallet] = _rOwned[burnWallet].add(rBurn);

            if(_isExcluded[burnWallet])  _tOwned[burnWallet] = _tOwned[burnWallet].add(tBurn);

            emit Transfer(sender, burnWallet, tBurn);

            uint256 rMarketing = tMarketing.mul(currentRate);
            _rOwned[marketingWallet] = _rOwned[marketingWallet].add(rMarketing);

            if(_isExcluded[marketingWallet]) _tOwned[marketingWallet] = _tOwned[marketingWallet].add(tMarketing);
    
            emit Transfer(sender, marketingWallet, tMarketing);
        }
    }

    function _transferToExcluded(address sender,address recipient,uint256 tAmount) private   {
       (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeMarketingAndBurnToken(tMarketingAndBurn, sender);
        _distributionToAllHolder(rDistribution, tDistribution);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeMarketingAndBurnToken(tMarketingAndBurn, sender);
        _distributionToAllHolder(rDistribution, tDistribution);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender,address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _takeMarketingAndBurnToken(tMarketingAndBurn, sender);
        _distributionToAllHolder(rDistribution, tDistribution);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDistribution, uint256 tTransferAmount, uint256 tDistribution, uint256 tMarketingAndBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeMarketingAndBurnToken(tMarketingAndBurn, sender);
        _distributionToAllHolder(rDistribution, tDistribution);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}
