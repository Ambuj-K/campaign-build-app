// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ICampaignSale.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract CampaignSale is ICampaignSale , Ownable, ReentrancyGuard{

    IERC20 public s_campaignToken;

    // Counter for token id counter
    using Counters for Counters.Counter;  
    Counters.Counter internal s_campaignCounter;

    mapping (uint256 => Campaign) internal s_campaignIDToCampaignObject;
    mapping (address => mapping(uint256 => uint256)) internal s_userAddressToContribution;

    // "require" string is gas expensive, so custom descriptive errors
    // launchcampaign errors
    error Campaign_StartAtLesserThanToday();
    error Campaign_StartDateGreaterThanEnd();
    error Campaign_RequestedCampaignGreaterThan90days();
    error Campaign_InvalidGoal();

    // cancel campaign errors
    error Campaign_CancelCampaignTimingError();

    // contribute/withdraw errors
    error Campaign_NotActiveAnymore();
    error Campaign_OutOfCampaignStartAndEndTime();
    error Campaign_AmtWithdrawnGreaterThanContribution();
    error Campaign__TokenTransferToContractFailed();
    error Campaign__TokenTransferToUserFailed();

    // claim campaign errors
    error Campaign_NonCreatorClaim();
    error Campaign_AmtPledgedLesserThanGoal();
    error Campaign_ClaimFailedWhileCampaignRunning();
    error Campaign__BalanceTokenToOwnerFailed();

    // refund campaign errors
    error Campaign_GoalReachedRefundError();
    error Campaign__RefundToUserFailed();
    error Campaign_NoContributionToRefund();

    constructor(address _campaignToken){
        s_campaignToken = IERC20(_campaignToken);
    }

    function launchCampaign(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        if( _startAt<uint32(block.timestamp + 1 days)){
            revert Campaign_StartAtLesserThanToday();
        }

        if ( _startAt > _endAt){
            revert Campaign_StartDateGreaterThanEnd();
        }

        if ( _endAt - _startAt>uint32(90 days)){
            revert Campaign_RequestedCampaignGreaterThan90days();
        }

        if ( _goal <= 0){
            revert Campaign_InvalidGoal();
        }

        Campaign memory s_campaignObj = Campaign(
            msg.sender,
            _goal,
            0,
            _startAt,
            _endAt,
            false
        );

        uint256 campaignId = s_campaignCounter.current();
        s_campaignCounter.increment();
        s_campaignIDToCampaignObject[campaignId] = s_campaignObj;

        // emit LaunchCampaign event
        emit LaunchCampaign(
        campaignId,
        msg.sender,
        _goal,
        _startAt,
        _endAt);
    }

    /// @notice Cancel a campaign
    /// @param _id Campaign's id
    function cancelCampaign(uint _id) external onlyOwner{
        if (s_campaignIDToCampaignObject[_id].startAt<block.timestamp){
            revert Campaign_CancelCampaignTimingError();
        }
        // all values in campaign struct 0
        delete s_campaignIDToCampaignObject[_id];
        emit CancelCampaign(_id);
    }

    /// @notice Contribute to the campaign for the given amount
    /// @param _id Campaign's id
    /// @param _amount Amount of the contribution    
    function contribute(uint _id, uint _amount) external nonReentrant {
        // goal 0 checked pre campaign creation, so it being 0 means campaign cancelled
        if (s_campaignIDToCampaignObject[_id].goal==0){
            revert Campaign_NotActiveAnymore();
        }
        if (s_campaignIDToCampaignObject[_id].startAt<=block.timestamp && block.timestamp<=s_campaignIDToCampaignObject[_id].endAt){
            revert Campaign_OutOfCampaignStartAndEndTime();
        }
        // in the frontend tokencontract function approve by user acct
        bool success = s_campaignToken.transferFrom(msg.sender, address(this), _amount);
        if (!success){
            revert Campaign__TokenTransferToContractFailed();
        }
        s_userAddressToContribution[msg.sender][_id] = s_userAddressToContribution[msg.sender][_id] + _amount;
        s_campaignIDToCampaignObject[_id].pledged = s_campaignIDToCampaignObject[_id].pledged + _amount;

        emit Contribute(_id, msg.sender, _amount);
    }

    /// @notice Withdraw an amount from your contribution
    /// @param _id Campaign's id
    /// @param _amount Amount of the contribution to withdraw
    function withdraw(uint _id, uint _amount) external nonReentrant {
        if (s_campaignIDToCampaignObject[_id].goal==0){
            revert Campaign_NotActiveAnymore();
        }
        if (s_campaignIDToCampaignObject[_id].startAt<=block.timestamp && block.timestamp<=s_campaignIDToCampaignObject[_id].endAt){
            revert Campaign_OutOfCampaignStartAndEndTime();
        }
        if (s_userAddressToContribution[msg.sender][_id] < _amount){
            revert Campaign_AmtWithdrawnGreaterThanContribution();
        }
        bool success = s_campaignToken.transfer(msg.sender, _amount);
        if (!success){
            revert Campaign__TokenTransferToUserFailed();
        }
        s_userAddressToContribution[msg.sender][_id] = s_userAddressToContribution[msg.sender][_id] - _amount;
        s_campaignIDToCampaignObject[_id].pledged = s_campaignIDToCampaignObject[_id].pledged - _amount;
        emit Withdraw(_id, msg.sender, _amount);
    }

    /// @notice Claim all the tokens from the campaign
    /// @param _id Campaign's id
    function claimCampaign(uint _id) external nonReentrant {
        if (msg.sender != s_campaignIDToCampaignObject[_id].creator){
            revert Campaign_NonCreatorClaim();
        }
        if (s_campaignIDToCampaignObject[_id].pledged < s_campaignIDToCampaignObject[_id].goal){
            revert Campaign_AmtPledgedLesserThanGoal();
        }
        if (s_campaignIDToCampaignObject[_id].startAt<=block.timestamp && block.timestamp<=s_campaignIDToCampaignObject[_id].endAt){
            revert Campaign_ClaimFailedWhileCampaignRunning();
        }
        uint256 campaignBalance = s_campaignIDToCampaignObject[_id].pledged;
        s_campaignIDToCampaignObject[_id].claimed=true;
        bool success = s_campaignToken.transfer(msg.sender, campaignBalance);
        if (!success){
            revert Campaign__BalanceTokenToOwnerFailed();
        }
        emit ClaimCampaign(_id);
    }

    /// @notice Refund all the tokens to the sender
    /// @param _id Campaign's id
    function refundCampaign(uint _id) external onlyOwner nonReentrant {
        if (s_campaignIDToCampaignObject[_id].pledged < s_campaignIDToCampaignObject[_id].goal){
            revert Campaign_GoalReachedRefundError();
        }
        uint256 amtRefund = s_userAddressToContribution[msg.sender][_id];
        if (s_userAddressToContribution[msg.sender][_id] == 0){
            revert Campaign_NoContributionToRefund();
        }
        bool success = s_campaignToken.transfer(msg.sender,amtRefund);
        if (!success){
            revert Campaign__RefundToUserFailed();
        }
        s_campaignIDToCampaignObject[_id].pledged = s_campaignIDToCampaignObject[_id].pledged - amtRefund;
        emit RefundCampaign(_id, msg.sender, amtRefund); 
    }

    /// @notice Get the campaign info
    /// @param _id Campaign's id
    function getCampaign(uint _id) view external returns (Campaign memory campaign) {
        return s_campaignIDToCampaignObject[_id];
    }

}