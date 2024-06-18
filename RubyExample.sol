// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Ruby_Token_Example is Context,Ownable,IERC20 {

    using SafeMath for uint256;
    using Address for address;
    
    uint8 private _decimals = 8;
    string private _symbol = "RUBY";
    string private _name = "Ruby Inu Example";

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _totalTokenSupply= 100000000000000000*10**8 wei;
    uint256 internal _reflectionTotal = (MAX % _totalTokenSupply);

    uint256 public _rewardsFee = 3; // 100 = 3% Static Rewards
    uint256 public _burnFee = 2; // 100 = 2% Burn
    uint256 public _burnFeeTotal;
    uint256 public _rewardFeeTotal;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD; // Burn Address
  
    mapping(address => mapping(address => uint256)) internal _allowances;
    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;

    mapping(address => bool) isExcludedFromFee;
    mapping(address => bool) internal _isExcluded;

    address[] internal _excluded;

    event RewardsDistributed(uint256 amount);

    constructor(){
        _tokenBalance[_msgSender()] = _totalTokenSupply;
        isExcludedFromFee[_msgSender()] = true; 
        isExcludedFromFee[address(this)] = true;
        _reflectionBalance[_msgSender()] =_reflectionTotal;

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
    
    function totalSupply() public override view returns(uint256){
        return _totalTokenSupply;
    }

    function transfer(address to, uint256 amount) public override virtual returns (bool) {
        _transfer(msg.sender, to,  amount);
        return true;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return _tokenBalance[tokenOwner];
    }

    function allowance(address owner, address spender) public view  override returns (uint256){
        return _allowances[owner][spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    
    function transferFrom(address spenderOwner, address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(spenderOwner,recipient,amount);
               
        _approve(spenderOwner,_msgSender(),_allowances[spenderOwner][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
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
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 transferAmount = amount;
        uint256 rate = 2;
         if(!isExcludedFromFee[from] && !isExcludedFromFee[to]){
            transferAmount = collectFee(from,amount,rate);
        }

        _tokenBalance[to] = _tokenBalance[to].add(transferAmount);
        _tokenBalance[from] =  _tokenBalance[from].sub(transferAmount,"ERC20: transfer amount exceeds allowance");

        emit Transfer(from, to, transferAmount);
    }

    function _burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        require(account == msg.sender);
        
        // _reflectionBalance[account] = _reflectionBalance[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalTokenSupply = _totalTokenSupply.sub(amount);
        _tokenBalance[account] =  _tokenBalance[account].sub(amount);
        // _moveDelegates(_delegates[account], _delegates[address(0)], amount);
        emit Transfer(account, address(0), amount);
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function excludeAccount(address account) external onlyOwner {
        require(account !=address(this),"contract it self cannot be excluded");
        require(!_isExcluded[account], " Account is already excluded");
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        for(uint256 i=0;i<_excluded.length; i++ ){
            if(_excluded[i] == account){
                _isExcluded[account] = true;
                _excluded.pop();
                break;
            }
        }
    }


    function collectFee(address sender,uint256 amount,uint256 rate) private returns (uint256) {
        uint256 transferAmount = amount;
        uint256 charityFee = amount.mul(_burnFee).div(100);
        uint256 taxFee = amount.mul(_rewardsFee).div(100);
        
        if(charityFee > 0){
            transferAmount = transferAmount.sub(charityFee);
            // _reflectionBalance[burnAddress] = _reflectionBalance[burnAddress].add(burnFee.mul(rate));
            _burnFeeTotal = _burnFeeTotal.add(charityFee);
            emit Transfer(sender,burnAddress,charityFee);
        }

        if (taxFee > 0) {
            transferAmount = transferAmount.sub(taxFee);
            // _reflectionTotal = _reflectionTotal.sub(taxFee.mul(rate));
            _rewardFeeTotal = _rewardFeeTotal.add(taxFee);
            emit RewardsDistributed(taxFee);
        }

        return transferAmount;
    }

    function setRewardFee(uint256 fee) public onlyOwner {
        _rewardsFee = fee;
    }
    
    function setNewBurnFee(uint256 fee) public onlyOwner {
        _burnFee = fee;
    }

    function setNewBurnAddress(address _Address) public onlyOwner {
        require(_Address != burnAddress);
        burnAddress = _Address;
    }

    function mint(uint256 amount) public onlyOwner returns(bool) {
     
        _totalTokenSupply = _totalTokenSupply.add(amount);
        _tokenBalance[ _msgSender()] = _tokenBalance[ _msgSender()].add(amount);
        emit Transfer(address(0),  _msgSender(), amount);
        return true;
    }

    receive() external payable {}

}