// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/LinkTokenReceiver.sol";
import "@chainlink/contracts/src/v0.6/interfaces/ChainlinkRequestInterface.sol";
import "@chainlink/contracts/src/v0.6/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

//This contract can be used by developers to test their contract
contract MockOracle is ChainlinkRequestInterface, LinkTokenReceiver {
  using SafeMathChainlink for uint256;

  uint256 constant public EXPIRY_TIME = 5 minutes;
  uint256 constant private MINIMUM_CONSUMER_GAS_LIMIT = 400000;
  
  struct Request {
      address callbackAddr;
      bytes4 callbackFunctionId;
  }

  LinkTokenInterface internal LinkToken;
  mapping(bytes32 => Request) private commitments;

  event OracleRequest(
    bytes32 indexed specId,
    address requester,
    bytes32 requestId,
    uint256 payment,
    address callbackAddr,
    bytes4 callbackFunctionId,
    uint256 cancelExpiration,
    uint256 dataVersion,
    bytes data
  );

  event CancelOracleRequest(
    bytes32 indexed requestId
  );


  //Deploy with the address of LINK token
  //_link --> Address of link token
  constructor(address _link)
    public
  {
    LinkToken = LinkTokenInterface(_link); // external but already deployed and unalterable
  }


  //This function is used to create a ChainLink Request
  //_sender --> Sender of the request
  //_payment --> Amount sent
  //_specId --> Job Specification ID
  //_callbackAddress --> Call back address for the response
  //_callbackFunctionId --> Call back function ID for response
  //_nonce --> Nonce sent by the one who made request
  //_dataVersion --> Version of data
  //_data --> COBR payload of request
  function oracleRequest(
    address _sender,
    uint256 _payment,
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionId,
    uint256 _nonce,
    uint256 _dataVersion,
    bytes calldata _data
  )
    external
    override
    onlyLINK()
    checkCallbackAddress(_callbackAddress)
  {
    bytes32 requestId = keccak256(abi.encodePacked(_sender, _nonce));
    require(commitments[requestId].callbackAddr == address(0), "Must use a unique ID");
    uint256 expiration = now.add(EXPIRY_TIME);

    commitments[requestId] = Request(
        _callbackAddress,
        _callbackFunctionId
    );

    emit OracleRequest(
      _specId,
      _sender,
      requestId,
      _payment,
      _callbackAddress,
      _callbackFunctionId,
      expiration,
      _dataVersion,
      _data);
  }


  //This function is called by the ChainLink node to fulfill requests. It returns if the external call was
  //successful or not.
  //_requestId --> Request ID that must match the ID of the one who made request
  //_data --> Data to return to consuming contract
  function fulfillOracleRequest(
    bytes32 _requestId,
    bytes32 _data
  )
    external
    isValidRequest(_requestId)
    returns (bool)
  {
    Request memory req = commitments[_requestId];
    delete commitments[_requestId];
    require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");

    (bool success, ) = req.callbackAddr.call(abi.encodeWithSelector(req.callbackFunctionId, _requestId, _data));
    return success;
  }


  //This function allows the requester to cancel the request sent to oracle contract. It tranfers the LINK
  //sent for the request back to requester's address.
  //_requestID --> Request ID
  //_payment --> Amount of payment given
  //_expiration --> Time of expiration for request
  function cancelOracleRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4,
    uint256 _expiration
  )
    external
    override
  {
    require(commitments[_requestId].callbackAddr != address(0), "Must use a unique ID");
    require(_expiration <= now, "Request is not expired");

    delete commitments[_requestId];
    emit CancelOracleRequest(_requestId);

    assert(LinkToken.transfer(msg.sender, _payment));
  }


  // This function returns address of LINK token
  function getChainlinkToken()
    public
    view
    override
    returns (address)
  {
    return address(LinkToken);
  }

  //Modifier used to revert request ID if it does not exist
  modifier isValidRequest(bytes32 _requestId) {
    require(commitments[_requestId].callbackAddr != address(0), "Must have a valid requestId");
    _;
  }


  //Modifier used to revert if callback address is LINK token
  modifier checkCallbackAddress(address _to) {
    require(_to != address(LinkToken), "Cannot callback to LINK");
    _;
  }

}