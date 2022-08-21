// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract EStorage {

    // currenct esusu id
    uint256 currentEsusuCycleId;

    // EsusuCyleStatus Struct
    enum EsusuStatus {
        Idle,
        Start,
        End
    }

    // EsusuCycle Struct
    struct EsusuCycle {
        uint256 amount;
        string name;
        uint256 depositedAmount;
        uint256 totalDepositedAmount;
        uint256 totalMembers;
        uint256 maxMembers;
        address payable owner;
        EsusuStatus status;
    }

    // EsusuCycleMember Struct
    struct EsusuMember {
        uint256 esusuCycleId;
        address member;
        uint256 totalAmountDepositedInCycle;
        uint256 totalPayoutReceivedInCycle;
    }

    mapping(uint256 => EsusuCycle) esusuCycles;
    mapping(address => mapping(uint256 => EsusuMember)) esusuCycleMembers;

    uint256 totalDeposits;

    //  Get the EsusuCycle Array
    function getEsusuCycles() external view returns (EsusuCycle[] memory) {
        return esusuCycles;
    }

    // Get esusu cycle status 
    function getEsusuCycleStatus(uint256 esusuId)
        external
        view
        returns (uint256)
    {
        return uint256(esusuCycles[esusuId].status);
    }
    
    // Get user total deposit
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }


    // Create Esusu
    function createEsusu(
        string calldata name,
        uint256 depositAmount,
        uint256 payoutIntervalSeconds,
        uint256 startTimeInSeconds,
        address owner,
        uint256 maxMembers
    ) external {
        currentEsusuCycleId += 1;
        EsusuCycle storage cycle = esusuCycles[currentEsusuCycleId];
        cycle.name = name;
        cycle.depositedAmount = depositedAmount;
        cycle.totalDepositedAmount = depositAmount;
        cycle.status = Start.Idle;
        cycle.owner = owner;
        cycle.maxMembers = maxMembers;
    }


    // Increase total deposit in cycle
    function increaseTotalAmountDepositedInCycle(
        uint256 esusuCycleId,
        uint256 amount
    ) external isCycleIdValid(esusuCycleId) returns (uint256) {
        EsusuCycle storage cycle = esusuCycles[esusuCycleId];

        uint256 amountDeposited = cycle.totalAmountDeposited.add(amount);

        cycle.totalAmountDeposited = amountDeposited;

        return amountDeposited;
    }


    // Create member
    function createMember(address member, uint256 esusuCycleId)
        external
        isCycleIdValid(esusuCycleId)
    {
        mapping(uint256 => EsusuMember) storage member = esusuCycleMembers[
            member
        ];

        member[esusuCycleId].esusuId = esusuCycleId;
        member[esusuCycleId].member = member;
        member[esusuCycleId].totalAmountDepositedInCycle = memberCycleMapping[
            esusuCycleId
        ].totalAmountDepositedInCycle.add(
                esusuCycles[esusuCycleId].depositAmount
            );
    }


    // Get esusu cycle info
    function getEsusuCycleInfo(uint256 esusuCycleId)
        external
        view
        isCycleIdValid(esusuCycleId)
        returns (
            uint256 esusuCycleId,
            uint256 depositAmount,
            uint256 status,
            uint256 totalMembers,
            uint256 maxMembers
        )
    {
        EsusuCycle memory cycle = esusuCycles[esusuCycleId];

        return (
            cycle.esusuCycleId,
            cycle.depositAmount,
            uint256(cycle.status),
            cycle.totalMembers,
            cycle.maxMembers
        );
    }


    // Start esusu cycle
    function StartEsusuCycle(uint256 esusuCycleId) public {
        //  Get Esusu Cycle Basic information
        (
            uint256 esusuCycleId,
            uint256 depositAmount,
            uint256 status,
            uint256 totalMembers,
            uint256 MaxMembers
        ) = getEsusuCycleInfo(esusuCycleId);

        //  Get Esusu Cycle Total Shares
        uint256 EsusuCycleTotalShares = _esusuStorage.GetEsusuCycleTotalShares(
            esusuCycleId
        );

        //  If cycle ID is valid, else bonunce
        require(
            esusuCycleId != 0 && esusuCycleId <= currentEsusuCycleId,
            "Cycle ID must be within valid EsusuCycleId range"
        );

        require(
            status == uint256(CycleStateEnum.Idle),
            "Cycle can only be started when in Idle state"
        );

        require(
            totalMembers >= 2,
            "Cycle can only be started with 2 or more members"
        );

        //  Get all the dai deposited for this cycle
        uint256 esusuCycleBalance = _esusuStorage
            .GetEsusuCycleTotalAmountDeposited(esusuCycleId);

        //  Update Esusu Cycle State, total cycle duration, total shares  and  cycle start time,
        _esusuStorage.UpdateEsusuCycleDuringStart(
            CycleId,
            uint256(CycleStateEnum.Active),
            toalCycleDuration,
            EsusuCycleTotalShares,
            now
        );
    }


    // Update Esusu Status
    function updateEsusuCycleStatus(uint256 esusuCycleId, uint256 status)
        external
    {
        EsusuCycle storage cycle = EsusuCycleMapping[esusuCycleId];

        cycle.status = EsusuStatus(status);
    }

    // Check if member already join esusu cycle
    function isMemberInCycle(address memberAddress, uint256 esusuCycleId)
        external
        view
        returns (bool)
    {
        return esusuCycleMembers[memberAddress][esusuCycleId].esusuId > 0;
    }


    // Check if cycleId is valid
    modifier isCycleIdValid(uint256 cycleId) {
        require(
            cycleId != 0 && cycleId <= esusuCycleId,
            "Cycle ID must be within valid EsusuCycleId range"
        );
        _;
    }
}
