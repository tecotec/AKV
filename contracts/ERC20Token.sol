pragma solidity ^0.4.18;

import './GroupLockup.sol';
import './ERC223/ERC223Token.sol';
import './ERC223/ERC223ContractInterface.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract ERC20Token is ERC223Token{
	using SafeMath for uint256;

	string public constant name = 'Akiverse Governance';
	string public constant symbol = 'AKV';
	uint8 public constant decimals = 18;
	uint256 public constant INITIAL_SUPPLY = 30000000000 * (10 ** uint256(decimals));
	uint256 public constant INITIAL_SALE_SUPPLY = 12000000000 * (10 ** uint256(decimals));
	uint256 public constant INITIAL_UNSALE_SUPPLY = INITIAL_SUPPLY - INITIAL_SALE_SUPPLY;

	address public owner_wallet;
	address public unsale_owner_wallet;

	GroupLockup public group_lockup;

	event BatchTransferFail(address indexed from, address indexed to, uint256 value, string msg);

	/**
	* @dev Constructor that gives msg.sender all of existing tokens.
	*/
	constructor(address _sale_owner_wallet, address _unsale_owner_wallet, GroupLockup _group_lockup) public {
		group_lockup = _group_lockup;
		owner_wallet = _sale_owner_wallet;
		unsale_owner_wallet = _unsale_owner_wallet;

		mint(owner_wallet, INITIAL_SALE_SUPPLY);
		mint(unsale_owner_wallet, INITIAL_UNSALE_SUPPLY);

		finishMinting();
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function sendTokens(address _to, uint256 _value) onlyOwner public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[owner_wallet]);

		bytes memory empty;
		
		// SafeMath.sub will throw if there is not enough balance.
		balances[owner_wallet] = balances[owner_wallet].sub(_value);
		balances[_to] = balances[_to].add(_value);

	    bool isUserAddress = false;
	    // solium-disable-next-line security/no-inline-assembly
	    assembly {
	      isUserAddress := iszero(extcodesize(_to))
	    }

	    if (isUserAddress == false) {
	      ERC223ContractInterface receiver = ERC223ContractInterface(_to);
	      receiver.tokenFallback(msg.sender, _value, empty);
	    }

		emit Transfer(owner_wallet, _to, _value);
		return true;
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(_value > 0);

		bytes memory empty;

		bool inLockupList = group_lockup.inLockupList(msg.sender);

		//if user in the lockup list, they can only transfer token after lockup date
		if(inLockupList){
			uint256 lockupTime = group_lockup.getLockupTime(msg.sender);
			require( group_lockup.isLockup(lockupTime) == false );
		}

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

	    bool isUserAddress = false;
	    // solium-disable-next-line security/no-inline-assembly
	    assembly {
	      isUserAddress := iszero(extcodesize(_to))
	    }

	    if (isUserAddress == false) {
	      ERC223ContractInterface receiver = ERC223ContractInterface(_to);
	      receiver.tokenFallback(msg.sender, _value, empty);
	    }

		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	* @param _data The data info.
	*/
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(_value > 0);

		bool inLockupList = group_lockup.inLockupList(msg.sender);

		//if user in the lockup list, they can only transfer token after lockup date
		if(inLockupList){
			uint256 lockupTime = group_lockup.getLockupTime(msg.sender);
			require( group_lockup.isLockup(lockupTime) == false );
		}

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

	    bool isUserAddress = false;
	    // solium-disable-next-line security/no-inline-assembly
	    assembly {
	      isUserAddress := iszero(extcodesize(_to))
	    }

	    if (isUserAddress == false) {
	      ERC223ContractInterface receiver = ERC223ContractInterface(_to);
	      receiver.tokenFallback(msg.sender, _value, _data);
	    }

	    emit Transfer(msg.sender, _to, _value);
		emit TransferERC223(msg.sender, _to, _value, _data);
		return true;
	}	


	/**
	* @dev transfer token to mulitipule user
	* @param _from which wallet's token will be taken.
	* @param _users The address list to transfer to.
	* @param _values The amount list to be transferred.
	*/
	function batchTransfer(address _from, address[] _users, uint256[] _values) onlyOwner public returns (bool) {

		address to;
		uint256 value;
		bool isUserAddress;
		bool canTransfer;
		string memory transferFailMsg;

		for(uint i = 0; i < _users.length; i++) {

			to = _users[i];
			value = _values[i];
			isUserAddress = false;
			canTransfer = false;
			transferFailMsg = "";

			// can not send token to contract address
		    //コントラクトアドレスにトークンを発送できない検証
		    assembly {
		      isUserAddress := iszero(extcodesize(to))
		    }

		    //data check
			if(!isUserAddress){
				transferFailMsg = "try to send token to contract";
			}else if(value <= 0){
				transferFailMsg = "try to send wrong token amount";
			}else if(to == address(0)){
				transferFailMsg = "try to send token to empty address";
			}else if(value > balances[_from]){
				transferFailMsg = "token amount is larger than giver holding";
			}else{
				canTransfer = true;
			}

			if(canTransfer){
			    balances[_from] = balances[_from].sub(value);
			    balances[to] = balances[to].add(value);
			    emit Transfer(_from, to, value);
			}else{
				emit BatchTransferFail(_from, to, value, transferFailMsg);
			}

        }

        return true;
	}
}

