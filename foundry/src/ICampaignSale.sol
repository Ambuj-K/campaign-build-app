// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Interface that should implement your CampaignSale contract
/// The constructor should have the ERC20 token address as argument
interface ICampaignSale {
    /// @notice Event when a campaign is lauched
    /// @param id Campaign's id based on a counter (starting from 1) 
    /// @param creator creator of the campaign (sender)
    /// @param goal Goal to reach for a successful campaign
    /// @param startAt Starting date of the campaign
    /// @param endAt Ending date of the campaign    
    event LaunchCampaign(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );

    /// @notice Event when a campaign is cancelled
    /// @param id Campaign's id    
    event CancelCampaign(uint id);

    /// @notice Event when a user contributes to the campaign
    /// @param id Campaign's id
    /// @param caller address of the contributor (sender)
    /// @param amount amount of the contribution  
    event Contribute(uint indexed id, address indexed caller, uint amount);

    /// @notice Event when a user withdraws an amount from his contribution to a campaign
    /// @param id Campaign's id
    /// @param caller address of the withdrawer (sender)
    /// @param amount amount of the withdraw    
    event Withdraw(uint indexed id, address indexed caller, uint amount);

    /// @notice Event when a campaign is claimed
    /// @param id Campaign's id
    event ClaimCampaign(uint id);

    /// @notice Event when a campaign is refunded
    /// @param id Campaign's id
    /// @param caller tokens receiver (sender)
    /// @param amount amount of tokens (all the contribution)
    event RefundCampaign(uint id, address indexed caller, uint amount);    

    /// @notice Object representing a campaign that should be used
    struct Campaign {
        // Creator of campaign
        address creator;
        // Amount of tokens to raise
        uint goal;
        // Total amount pledged
        uint pledged;
        // Timestamp of start of campaign
        uint32 startAt;
        // Timestamp of end of campaign
        uint32 endAt;
        // True if goal was reached and creator has claimed the tokens.
        bool claimed;
    }

    /// @notice Launch a new campaign. 
    /// @param _goal The goal in token to raise to unlock the tokens for the project
    /// @param _startAt Starting date of the campaign
    /// @param _endAt Ending date of the campaign
    function launchCampaign(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external;  

    /// @notice Cancel a campaign
    /// @param _id Campaign's id
    function cancelCampaign(uint _id) external;

    /// @notice Contribute to the campaign for the given amount
    /// @param _id Campaign's id
    /// @param _amount Amount of the contribution    
    function contribute(uint _id, uint _amount) external;

    /// @notice Withdraw an amount from your contribution
    /// @param _id Campaign's id
    /// @param _amount Amount of the contribution to withdraw
    function withdraw(uint _id, uint _amount) external;

    /// @notice Claim all the tokens from the campaign
    /// @param _id Campaign's id
    function claimCampaign(uint _id) external;

    /// @notice Refund all the tokens to the sender
    /// @param _id Campaign's id
    function refundCampaign(uint _id) external;

    /// @notice Get the campaign info
    /// @param _id Campaign's id
    function getCampaign(uint _id) external returns (Campaign memory campaign);
}