pragma solidity ^0.4.21;


import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


/**
 * @title BatchTransferable
 * @dev Base contract which allows children to run batch transfer token.
 */
contract BatchTransferable is Ownable {
  event BatchTransferStop();

  bool public batchTransferStopped = false;


  /**
   * @dev Modifier to make a function callable only when the contract is do batch transfer token.
   */
  modifier whenBatchTransferNotStopped() {
    require(!batchTransferStopped);
    _;
  }

  /**
   * @dev called by the owner to stop, triggers stopped state
   */
  function batchTransferStop() onlyOwner whenBatchTransferNotStopped public {
    batchTransferStopped = true;
    emit BatchTransferStop();
  }

  /**
   * @dev called to check that can do batch transfer or not
   */
  function isBatchTransferStop() public view returns (bool){
    return batchTransferStopped;
  }

}
