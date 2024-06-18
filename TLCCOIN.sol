// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TLCCOIN is Ownable,IERC20 {
    using SafeMath for uint256;

    uint256 constant public decimals = 8; //How many decimals to show.
    uint256 private _totalSupply = 4200000000 * 10**8 ; 
    string constant public name = "The Love Care Coin"; //fancy name: eg BLOCKCHAIN 420
    string constant public symbol = "TLCC"; //An identifier: eg TLCC
    string constant public version = "v2";       //Version 2 standard. Just an arbitrary versioning scheme.

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    constructor(){
        balances[_msgSender()] = _totalSupply;
    }

    function freezeAccount(address target, bool freeze)public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function totalSupply() public view override returns (uint256){
        return _totalSupply;
    }

    function allowance(address _owner, address _spender)  public override view returns (uint256 ) {
      return allowed[_owner][_spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool success) {
        require(spender != address(0),"ERC20: transfer from the zero address"); // check address
        require(balances[_msgSender()] > amount && amount > 0 ,"Balances is not enough"); // Check if the sender has enough
        _approve(_msgSender(), spender, amount);

        return true;
    }

    function transfer(address _to, uint256 _amount) public override returns (bool success) {
        require(!frozenAccount[_msgSender()] ,"Your account is frozenaccount"); // Check for frozen account
        require(_amount > 0,"Balances is not enough");  // Check if the sender has enough and Don't allow 0value transfer
        _transfer(_msgSender(), _to,  _amount);

        return true;
    }

     function transferFrom(address _spenderOwner, address _recipient, uint256 _amount) public override returns (bool) {
        require(!frozenAccount[_msgSender()],"Your account is frozenaccount"); // Check for frozen account
        require(allowed[_spenderOwner][_msgSender()] >= _amount ,"Value is more then approve amount"); // Check allowance amount
        require(_amount>0,"amount is not enough" );

        _transfer(_spenderOwner,_recipient,_amount);
        _approve(_spenderOwner,_msgSender(),allowed[_spenderOwner][_msgSender()].sub(_amount,"ERC20: transfer amount exceeds allowance"));

        return true;
    }

    function _transfer(address from,address to, uint256 amount) private {
        require(from != address(0),"ERC20: transfer from the zero address"); // check address
        require(to != address(0), "ERC20: transfer to the zero address");   // check address

        balances[to] = balances[to].add(amount);
        balances[from] = balances[from].sub(amount);
        emit Transfer(from, to, amount);
    } 

    function _approve(address owner,address spender,uint256 amount) private{
        require(owner != address(0), "ERC20: approve from the zero address"); // check address
        require(spender != address(0), "ERC20: approve to the zero address"); // check address
    
        allowed[owner][spender ] = amount;

        // Notify anyone listening that this approval done
        emit Approval(owner, spender, amount);
    }

  /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _amount, bytes memory _extraData) public returns (bool  ) {
        allowed[msg.sender][_spender] = _amount;
 
        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.

        (bool success, bytes memory data)  = address(_spender).call(abi.encode(
        bytes4(bytes32(keccak256(abi.encodePacked("receiveApproval(address,uint256,address,bytes)")))),msg.sender, _amount, this, _extraData));
        require(success);

        emit Approval(msg.sender, _spender, _amount);

        return true;
    }

}


/*
URL : https://ropsten.etherscan.io/address/0x4b5bbba7cac42492298ca6aecc69651ea45af5c9
contract address : 0x4b5bbba7caC42492298cA6aeCc69651eA45aF5c9
network : ropsten testnet

private key : 7982f7668ba3873e537cd07b3ff33a938bce39e153e68c4882be93f5a2b7a4bb 
TLCC address  :0x2E9AC46334c084A04056819048A1813d268EB5e0
*/