// SPDX-License-Identifier: MIT
pragma solidity ^0.4.11;

import "@chainlink/contracts/src/v0.4/ERC677Token.sol";
import {StandardToken as linkStandardToken} from "@chainlink/contracts/src/v0.4/vendor/StandardToken.sol";

contract LinkToken is linkStandardToken, ERC677Token {
    uint256 public constant totalSupply = 10**27;
    string public constant name = "ChainLink Token";
    uint8 public constant decimals = 18;
    string public constant symbol = "LINK";

    function LinkToken() public {
        balances[msg.sender] = totalSupply;
    }


    //Modifier to check valid recipient
    modifier validRecipient(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this));
        _;
    }


    //This function is used to transfer tokens to a specified address if the recipient is a contract.
    //_to --> Address to transfer funds to
    //_value --> Amount to be tranferred
    //_data --> Data to be passed to recieving contract
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes _data
    ) public validRecipient(_to) returns (bool success) {
        return super.transferAndCall(_to, _value, _data);
    }


    //This function is used to transfer tokens to the specified address
    //_to --> Address to tranfer funds to
    //_value --> Amount to be transferred
    function transfer(address _to, uint256 _value)
        public
        validRecipient(_to)
        returns (bool success)
    {
        return super.transfer(_to, _value);
    }


    //This function is used to approve the passed address to spend tokens on behalf of msg.sender
    //_spender --> Address that will spend funds
    //_value --> Amount of tokens to be spent
    function approve(address _spender, uint256 _value)
        public
        validRecipient(_spender)
        returns (bool)
    {
        return super.approve(_spender, _value);
    }


    //This function is used to transfer tokens from one address to another.
    //_from --> The address from where you want to send the tokens
    // _to --> The address where you want to send tokens to
    //_value --> The amount of tokens you want to send
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public validRecipient(_to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}