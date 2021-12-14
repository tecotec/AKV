pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract GroupLockup is Ownable{
	using SafeMath for uint256;

	mapping(address => uint256) public lockup_list; //users lockup list
	mapping(uint256 => bool) public lockup_list_flag;
	address[] public user_list; //users address list

	event UpdateLockupList(address indexed owner, address indexed user_address, uint256 lockup_date);
	event UpdateLockupTime(address indexed owner, uint256 indexed old_lockup_date, uint256 new_lockup_date);
	event LockupTimeList(uint256 indexed lockup_date, bool active);

	/**
	* @dev Function to get lockup list
	* @param user_address address 
	* @return A uint256 that indicates if the operation was successful.
	*/
	function getLockupTime(address user_address)public view returns (uint256){
		return lockup_list[user_address];
	}

	/**
	* @dev Function to check token locked date that is reach or not
	* @param lockup_date uint256 
	* @return A bool that indicates if the operation was successful.
	*/
	function isLockup(uint256 lockup_date) public view returns(bool){
		return (now < lockup_date);
	}

	/**
	* @dev Function get user's lockup status
	* @param user_address address
	* @return A bool that indicates if the operation was successful.
	*/
	function inLockupList(address user_address)public view returns(bool){
		if(lockup_list[user_address] == 0){
			return false;
		}
		return true;
	}

	/**
	* @dev Function update lockup status for purchaser, if user in the lockup list, they can only transfer token after lockup date
	* @param user_address address
	* @param lockup_date uint256 this user's token time
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockupList(address user_address, uint256 lockup_date)onlyOwner public returns(bool){
		if(lockup_date == 0){
			delete lockup_list[user_address];

			for(uint256 user_list_index = 0; user_list_index < user_list.length; user_list_index++) {
				if(user_list[user_list_index] == user_address){
					delete user_list[user_list_index];
					break;
				}
			}
		}else{
			bool user_is_exist = inLockupList(user_address);

			if(!user_is_exist){
				user_list.push(user_address);
			}

			lockup_list[user_address] = lockup_date;

			//insert lockup time into lockup time list, if this lockup time is the new one
			if(!lockup_list_flag[lockup_date]){
				lockup_list_flag[lockup_date] = true;
				emit LockupTimeList(lockup_date, true);
			}
			
		}
		emit UpdateLockupList(msg.sender, user_address, lockup_date);

		return true;
	}

	/**
	* @dev Function update lockup time
	* @param old_lockup_date uint256 old group lockup time
	* @param new_lockup_date uint256 new group lockup time
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockupTime(uint256 old_lockup_date, uint256 new_lockup_date)onlyOwner public returns(bool){
		require(old_lockup_date != 0);
		require(new_lockup_date != 0);
		require(new_lockup_date != old_lockup_date);

		address user_address;
		uint256 user_lockup_time;

		//update the user's lockup time who was be setted as old lockup time
		for(uint256 user_list_index = 0; user_list_index < user_list.length; user_list_index++) {
			if(user_list[user_list_index] != 0){
				user_address = user_list[user_list_index];
				user_lockup_time = getLockupTime(user_address);
				if(user_lockup_time == old_lockup_date){
					lockup_list[user_address] = new_lockup_date;
					emit UpdateLockupList(msg.sender, user_address, new_lockup_date);
				}
			}
		}

		//delete the old lockup time from lockup time list, if this old lockup time is existing in the lockup time list
		if(lockup_list_flag[old_lockup_date]){
			lockup_list_flag[old_lockup_date] = false;
			emit LockupTimeList(old_lockup_date, false);
		}

		//insert lockup time into lockup time list, if this lockup time is the new one
		if(!lockup_list_flag[new_lockup_date]){
			lockup_list_flag[new_lockup_date] = true;
			emit LockupTimeList(new_lockup_date, true);
		}

		emit UpdateLockupTime(msg.sender, old_lockup_date, new_lockup_date);
		return true;
	}
}
