// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EStorage.sol";

contract Esusu is Ownable, ERC20 {
    EStorage _eStorage;

    event JoinEsusuCycleEvent(
        uint256 date,
        address indexed member,
        uint256 esusuCycleId,
    );

    event StartEsusuCycleEvent(uint256 date, uint256 esusuCycleId);

    event CreateEsusuCycleEvent(uint256 date, string name, address Owner);

    constructor(uint256 _quantity) ERC20("Esusu Coorperative", "ESCT") {
        address _to = address(this);
        _mint(_to, _quantity);
    }

    function createEsusu(
        string calldata name,
        uint256 depositAmount,
        uint256 maxMembers,
        address owner
    ) external {
        require(depositAmount > 0, "Deposit Amount Can't Be Zero");

        _esusuAdapter.createEsusu(name, depositAmount, maxMembers, owner);

        emit CreateEsusuCycleEvent(now, name, owner);
    }

    function joinEsusu(uint256 esusuCycleId) public {
        //  Get Current EsusuCycleId
        uint256 currentEsusuCycleId = _esusuStorage.GetEsusuCycleId();

        //  Check if the cycle ID is valid
        require(
            esusuCycleId > 0 && esusuCycleId <= currentEsusuCycleId,
            "Cycle ID must be within valid EsusuCycleId range"
        );

        //  Get the Esusu Cycle struct

        (
            uint256 CycleId,
            uint256 DepositAmount,
            uint256 CycleState,
            uint256 TotalMembers,
            uint256 MaxMembers
        ) = _esusuStorage.GetEsusuCycleBasicInformation(esusuCycleId);
        //  If cycle is not in Idle State, bounce
        require(
            CycleState == uint256(Status.Idle),
            "Esusu Cycle must be in Idle State before you can join"
        );

        //  If cycle is filled up, bounce

        require(
            TotalMembers < MaxMembers,
            "Esusu Cycle is filled up, you can't join"
        );

        //  check if member is already in this cycle
        require(
            !_isMemberInCycle(member, esusuCycleId),
            "Member can't join same Esusu Cycle more than once"
        );

        //  If user does not have enough Balance, bounce. For now we use Dai as default
        uint256 memberBalance = _dai.balanceOf(member);

        require(
            memberBalance >= DepositAmount,
            "Balance must be greater than or equal to Deposit Amount"
        );

        _esusuStorage.createMember(member, esusuCycleId);

        //  Increase TotalMembers count by 1
        _esusuStorage.IncreaseTotalMembersInCycle(esusuCycleId);

        //  If user balance is greater than or equal to deposit amount then transfer from member to this contract
        //  NOTE: approve this contract to withdraw before transferFrom can work
        _dai.safeTransferFrom(member, address(this), DepositAmount);

        //  Increment the total deposited amount in this cycle
        _esusuStorage
            .increaseTotalAmountDepositedInCycle(CycleId, DepositAmount);

        //  Increase TotalDeposits made to this contract
        _esusuStorage.increaseTotalDeposits(DepositAmount);

        //  emit event
        emit JoinEsusuCycleEvent(
            now,
            member,
            esusuCycleId
        );
    }

    function startEsusuCycle(uint256 esusuCycleId) external {
        _esusuAdapter.StartEsusuCycle(esusuCycleId);

        emit JoinEsusuCycleEvent(now, esusuCycleId);
    }

    function _isMemberInCycle(address memberAddress, uint256 esusuCycleId)
        internal
        view
        returns (bool)
    {
        return _esusuStorage.IsMemberInCycle(memberAddress, esusuCycleId);
    }

}
