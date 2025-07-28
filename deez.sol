// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Deez Basic Crowdfunding
 * @dev Simple crowdfunding platform with 3 core functions
 * @author Your Name
 */
contract Deez {
    
    struct Campaign {
        address creator;
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
        bool goalReached;
        bool active;
    }
    
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    uint256 public campaignCount;
    
    event CampaignCreated(uint256 campaignId, address creator, string title, uint256 goal);
    event ContributionMade(uint256 campaignId, address contributor, uint256 amount);
    event GoalReached(uint256 campaignId, uint256 totalAmount);
    event FundsWithdrawn(uint256 campaignId, address creator, uint256 amount);
    event RefundClaimed(uint256 campaignId, address contributor, uint256 amount);
    
    /**
     * @dev Core Function 1: Create a new crowdfunding campaign
     * @param _title Campaign title
     * @param _description Campaign description  
     * @param _goal Funding goal in wei
     * @param _durationDays Campaign duration in days
     */
    function createCampaign(
        string memory _title, 
        string memory _description, 
        uint256 _goal, 
        uint256 _durationDays
    ) public returns (uint256) {
        require(_goal > 0, "Goal must be greater than 0");
        require(_durationDays > 0, "Duration must be greater than 0");
        
        campaignCount++;
        uint256 deadline = block.timestamp + (_durationDays * 1 days);
        
        campaigns[campaignCount] = Campaign({
            creator: msg.sender,
            title: _title,
            description: _description,
            goal: _goal,
            deadline: deadline,
            amountRaised: 0,
            goalReached: false,
            active: true
        });
        
        emit CampaignCreated(campaignCount, msg.sender, _title, _goal);
        return campaignCount;
    }
    
    /**
     * @dev Core Function 2: Contribute ETH to a campaign
     * @param _campaignId ID of campaign to contribute to
     */
    function contribute(uint256 _campaignId) public payable {
        require(_campaignId > 0 && _campaignId <= campaignCount, "Invalid campaign ID");
        require(msg.value > 0, "Must send ETH to contribute");
        
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.active, "Campaign is not active");
        require(block.timestamp < campaign.deadline, "Campaign deadline passed");
        
        contributions[_campaignId][msg.sender] += msg.value;
        campaign.amountRaised += msg.value;
        
        if (campaign.amountRaised >= campaign.goal && !campaign.goalReached) {
            campaign.goalReached = true;
            emit GoalReached(_campaignId, campaign.amountRaised);
        }
        
        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }
    
    /**
     * @dev Core Function 3: Withdraw funds (success) or get refund (failure)
     * @param _campaignId ID of campaign
     */
    function claimFunds(uint256 _campaignId) public {
        require(_campaignId > 0 && _campaignId <= campaignCount, "Invalid campaign ID");
        
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp >= campaign.deadline, "Campaign still active");
        
        if (campaign.goalReached) {
            // Campaign successful - creator withdraws
            require(msg.sender == campaign.creator, "Only creator can withdraw");
            require(campaign.active, "Funds already withdrawn");
            
            campaign.active = false;
            uint256 amount = campaign.amountRaised;
            
            payable(msg.sender).transfer(amount);
            emit FundsWithdrawn(_campaignId, msg.sender, amount);
            
        } else {
            // Campaign failed - contributors get refund
            uint256 contribution = contributions[_campaignId][msg.sender];
            require(contribution > 0, "No contribution to refund");
            
            contributions[_campaignId][msg.sender] = 0;
            payable(msg.sender).transfer(contribution);
            emit RefundClaimed(_campaignId, msg.sender, contribution);
        }
    }
    
    // View functions
    function getCampaign(uint256 _campaignId) public view returns (
        address creator,
        string memory title,
        string memory description,
        uint256 goal,
        uint256 deadline,
        uint256 amountRaised,
        bool goalReached,
        bool active
    ) {
        Campaign memory campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goal,
            campaign.deadline,
            campaign.amountRaised,
            campaign.goalReached,
            campaign.active
        );
    }
    
    function getContribution(uint256 _campaignId, address _contributor) public view returns (uint256) {
        return contributions[_campaignId][_contributor];
    }
    
    function isActive(uint256 _campaignId) public view returns (bool) {
        Campaign memory campaign = campaigns[_campaignId];
        return campaign.active && block.timestamp < campaign.deadline;
    }
}
