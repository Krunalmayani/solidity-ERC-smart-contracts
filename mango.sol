// SPDX-License-Identifier:MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract MangosToken is IERC20, Ownable{
    using SafeMath for uint256;

    uint256 public decimals =18;   //How many decimals to show.
    uint256 private totalSupply_;  // 4.45 billion tokens, 18 decimal places
    string constant public name = "MANGOSCOIN"; //fancy name: eg MANGO COIN
    string constant public symbol = "MANGO"; //An identifier: eg MANGO
    address[] private addressList;
    mapping (address => bool)  userAddr; 

    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event FrozenFunds(address target, bool frozen);
    
    constructor()  {
        balances[_msgSender()] = 250000e18;  // Give the creator all initial tokens
        totalSupply_ = 250000e18;
        emit Transfer(address(0), _msgSender(), totalSupply_);
    }

    function showUserAddress(uint256 uid) public view onlyOwner returns(address){
        return addressList[uid];
    }

    function totalUser() public view onlyOwner returns(uint256) {
        return addressList.length;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;

        emit FrozenFunds(target, freeze);
    }

    function totalSupply() public view override returns (uint256){
        return totalSupply_;
    }

    function allowance(address _owner, address _spender)  public override view returns (uint256 ) {
        return allowed[_owner][_spender];
    }
   
    function approve(address spender, uint256 amount) public override returns (bool success) {
       
        require(balances[_msgSender()]>= amount && amount > 0,"Balances is not enough"); // Check if the sender has enough
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) public override returns (bool success) {

        require(!frozenAccount[_msgSender()] ,"Your account is frozen account"); // Check for frozen account
        require(balances[_msgSender()]>= _amount && _amount > 0 ,"Amount is not enough");  // Check if the sender has enough

        _transfer(_msgSender(), _to, _amount);

        return true;
    }

    function transferFrom(address _spenderOwner, address _recipient, uint256 _amount) public override returns (bool) {
        require(!frozenAccount[_msgSender()],"Your account is frozen account"); // Check for frozen account
        require(!frozenAccount[_spenderOwner] ,"Spender owner's account is frozen account"); // Check for frozen account
        require(allowed[_spenderOwner][_msgSender()] >= _amount,"Amount is more then approve amount"); // Check allowance amount
        require(_amount > 0, "Transfer amount must be greater than zero");  // Don't allow 0Amount transfer
       
        _transfer(_spenderOwner,_recipient,_amount);
        _approve(_spenderOwner,_msgSender(),allowed[_spenderOwner][_msgSender()].sub(_amount,"ERC20: transfer amount exceeds allowance"));

        return true;
    }

    function _transfer(address from,address to, uint256 amount ) private {
        require(from != address(0),"ERC20: transfer from the zero address"); // check address
        require(to != address(0), "ERC20: transfer to the zero address");   // check address
    
        balances[to] = balances[to].add(amount);
        balances[from] = balances[from].sub(amount);
        emit Transfer(from, to, amount);

        for(uint i = 0; i <= addressList.length; i++) {
            if (userAddr[to] == false) {
                userAddr[to] = true;
                addressList.push(to);
            }
        }
    }
    
    function _approve(address owner, address spender ,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address"); // check address
        require(spender != address(0), "ERC20: approve to the zero address"); // check address
    
        allowed[owner][spender ] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        require(!frozenAccount[account],"Account is frozen account"); // Check for frozen account

        totalSupply_ += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }

    function _burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        totalSupply_ -= amount;

        emit Transfer(account, address(0), amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowed[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowed[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

}

// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
// 0x617F2E2fD72FD9D5503197092aC168c91465E7f2
