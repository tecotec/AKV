pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

contract ERC223Token is MintableToken{
  function transfer(address to, uint256 value, bytes data) public returns (bool);
  event TransferERC223(address indexed from, address indexed to, uint256 value, bytes data);
}
