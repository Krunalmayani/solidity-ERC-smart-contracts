// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BLOCKCHAIN420 is Ownable,IERC20 {

    using SafeMath for uint256;

    uint256 public decimals = 8;   //How many decimals to show.
    uint256 private totalSupply_ = 4200000000 * 10**8;  // 4.20 billion tokens, 8 decimal places
    string constant public name =  "The Love Care Coin"; //fancy name: eg BLOCKCHAIN 420
    string constant public symbol = "TLCC"; //An identifier: eg TLCC
    string constant public version = "v2";  //Version 2 standard. Just an arbitrary versioning scheme

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    constructor()  {
        balances[_msgSender()] = totalSupply_;  // Give the creator all initial tokens
        emit Transfer(address(0), _msgSender(), totalSupply_);
    }

    function mint(uint256 _amount) public onlyOwner returns(bool) {                                                                                                                                                                                         
        require(_amount > 0, "Amount must be greater than zero");  // Don't Mint 0 Amount 
        
        totalSupply_ = totalSupply_.add(_amount);
        balances[ _msgSender()] = balances[ _msgSender()].add(_amount);

        emit Transfer(address(0),  _msgSender(), _amount);
        return true;
    }

    // Only owner can freeze and unfreeze of account
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;

        emit FrozenFunds(target, freeze);
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function totalSupply() public view override returns (uint256){
        return totalSupply_;
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
    }
    
    function _approve(address owner, address spender ,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address"); // check address
        require(spender != address(0), "ERC20: approve to the zero address"); // check address
    
        allowed[owner][spender ] = amount;

        // Notify anyone listening that this approval done
        emit Approval(owner, spender, amount);
    }

    function allowance(address _owner, address _spender)  public override view returns (uint256 ) {
        return allowed[_owner][_spender];
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _amount, bytes memory _extraData) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
   
        (bool success, bytes memory data)  = (_spender).call(abi.encode( bytes4(bytes32(keccak256(abi.encodePacked("receiveApproval(address,uint256,address,bytes)")))), msg.sender, _amount, this, _extraData));
        require(success);
        
        return true;
    }

}
