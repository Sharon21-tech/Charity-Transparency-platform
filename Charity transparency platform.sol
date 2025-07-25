// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Charity Transparency Platform
 * @dev A smart contract for transparent charity operations with donation tracking and fund distribution
 * @author Charity Transparency Platform Team
 */
contract CharityTransparencyPlatform {
    
    // State variables
    address public owner;
    uint256 public totalDonations;
    uint256 public totalDisbursed;
    uint256 public charityCount;
    
    // Structs
    struct Charity {
        string name;
        string description;
        address charityAddress;
        uint256 totalReceived;
        uint256 totalSpent;
        bool isActive;
        uint256 registrationTime;
    }
    
    struct Donation {
        uint256 charityId;
        address donor;
        uint256 amount;
        uint256 timestamp;
        string message;
    }
    
    struct Expense {
        uint256 charityId;
        uint256 amount;
        string description;
        string category;
        uint256 timestamp;
        bool isVerified;
    }
    
    // Mappings
    mapping(uint256 => Charity) public charities;
    mapping(uint256 => Donation[]) public charityDonations;
    mapping(uint256 => Expense[]) public charityExpenses;
    mapping(address => uint256[]) public donorHistory;
    
    // Events
    event CharityRegistered(uint256 indexed charityId, string name, address charityAddress);
    event DonationMade(uint256 indexed charityId, address indexed donor, uint256 amount, string message);
    event FundsDistributed(uint256 indexed charityId, uint256 amount, string description, string category);
    event ExpenseVerified(uint256 indexed charityId, uint256 expenseIndex);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyActiveCharity(uint256 _charityId) {
        require(_charityId < charityCount, "Charity does not exist");
        require(charities[_charityId].isActive, "Charity is not active");
        _;
    }
    
    modifier onlyCharityOwner(uint256 _charityId) {
        require(charities[_charityId].charityAddress == msg.sender, "Not authorized charity address");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        totalDonations = 0;
        totalDisbursed = 0;
        charityCount = 0;
    }
    
    /**
     * @dev Core Function 1: Register a new charity on the platform
     * @param _name Name of the charity
     * @param _description Description of the charity's mission
     * @param _charityAddress Official address of the charity
     */
    function registerCharity(
        string memory _name,
        string memory _description,
        address _charityAddress
    ) public onlyOwner {
        require(_charityAddress != address(0), "Invalid charity address");
        require(bytes(_name).length > 0, "Charity name cannot be empty");
        
        charities[charityCount] = Charity({
            name: _name,
            description: _description,
            charityAddress: _charityAddress,
            totalReceived: 0,
            totalSpent: 0,
            isActive: true,
            registrationTime: block.timestamp
        });
        
        emit CharityRegistered(charityCount, _name, _charityAddress);
        charityCount++;
    }
    
    /**
     * @dev Core Function 2: Make a donation to a specific charity
     * @param _charityId ID of the charity to donate to
     * @param _message Optional message from the donor
     */
    function makeDonation(uint256 _charityId, string memory _message) 
        public 
        payable 
        onlyActiveCharity(_charityId) 
    {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        // Create donation record
        Donation memory newDonation = Donation({
            charityId: _charityId,
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: _message
        });
        
        // Update charity's total received
        charities[_charityId].totalReceived += msg.value;
        
        // Add to charity donations array
        charityDonations[_charityId].push(newDonation);
        
        // Add to donor's history
        donorHistory[msg.sender].push(_charityId);
        
        // Update global totals
        totalDonations += msg.value;
        
        emit DonationMade(_charityId, msg.sender, msg.value, _message);
    }
    
    /**
     * @dev Core Function 3: Distribute funds for charity expenses with transparency
     * @param _charityId ID of the charity
     * @param _amount Amount to be spent
     * @param _description Description of the expense
     * @param _category Category of expense (e.g., "Medical", "Education", "Food")
     */
    function distributeFunds(
        uint256 _charityId,
        uint256 _amount,
        string memory _description,
        string memory _category
    ) public onlyActiveCharity(_charityId) onlyCharityOwner(_charityId) {
        require(_amount > 0, "Amount must be greater than 0");
        require(charities[_charityId].totalReceived >= charities[_charityId].totalSpent + _amount, 
                "Insufficient funds");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        // Create expense record
        Expense memory newExpense = Expense({
            charityId: _charityId,
            amount: _amount,
            description: _description,
            category: _category,
            timestamp: block.timestamp,
            isVerified: false
        });
        
        // Add to charity expenses
        charityExpenses[_charityId].push(newExpense);
        
        // Update charity's total spent
        charities[_charityId].totalSpent += _amount;
        
        // Update global total disbursed
        totalDisbursed += _amount;
        
        // Transfer funds to charity address
        payable(charities[_charityId].charityAddress).transfer(_amount);
        
        emit FundsDistributed(_charityId, _amount, _description, _category);
    }
    
    // View functions for transparency
    
    /**
     * @dev Get charity information
     */
    function getCharityInfo(uint256 _charityId) 
        public 
        view 
        returns (
            string memory name,
            string memory description,
            address charityAddress,
            uint256 totalReceived,
            uint256 totalSpent,
            bool isActive
        ) 
    {
        require(_charityId < charityCount, "Charity does not exist");
        Charity memory charity = charities[_charityId];
        return (
            charity.name,
            charity.description,
            charity.charityAddress,
            charity.totalReceived,
            charity.totalSpent,
            charity.isActive
        );
    }
    
    /**
     * @dev Get donation count for a charity
     */
    function getDonationCount(uint256 _charityId) public view returns (uint256) {
        require(_charityId < charityCount, "Charity does not exist");
        return charityDonations[_charityId].length;
    }
    
    /**
     * @dev Get expense count for a charity
     */
    function getExpenseCount(uint256 _charityId) public view returns (uint256) {
        require(_charityId < charityCount, "Charity does not exist");
        return charityExpenses[_charityId].length;
    }
    
    /**
     * @dev Get specific donation details
     */
    function getDonation(uint256 _charityId, uint256 _donationIndex) 
        public 
        view 
        returns (
            address donor,
            uint256 amount,
            uint256 timestamp,
            string memory message
        ) 
    {
        require(_charityId < charityCount, "Charity does not exist");
        require(_donationIndex < charityDonations[_charityId].length, "Donation does not exist");
        
        Donation memory donation = charityDonations[_charityId][_donationIndex];
        return (donation.donor, donation.amount, donation.timestamp, donation.message);
    }
    
    /**
     * @dev Get specific expense details
     */
    function getExpense(uint256 _charityId, uint256 _expenseIndex) 
        public 
        view 
        returns (
            uint256 amount,
            string memory description,
            string memory category,
            uint256 timestamp,
            bool isVerified
        ) 
    {
        require(_charityId < charityCount, "Charity does not exist");
        require(_expenseIndex < charityExpenses[_charityId].length, "Expense does not exist");
        
        Expense memory expense = charityExpenses[_charityId][_expenseIndex];
        return (expense.amount, expense.description, expense.category, expense.timestamp, expense.isVerified);
    }
    
    /**
     * @dev Verify an expense (only owner can verify)
     */
    function verifyExpense(uint256 _charityId, uint256 _expenseIndex) public onlyOwner {
        require(_charityId < charityCount, "Charity does not exist");
        require(_expenseIndex < charityExpenses[_charityId].length, "Expense does not exist");
        
        charityExpenses[_charityId][_expenseIndex].isVerified = true;
        emit ExpenseVerified(_charityId, _expenseIndex);
    }
    
    /**
     * @dev Get donor's donation history
     */
    function getDonorHistory(address _donor) public view returns (uint256[] memory) {
        return donorHistory[_donor];
    }
    
    /**
     * @dev Get platform statistics
     */
    function getPlatformStats() 
        public 
        view 
        returns (
            uint256 totalDonationsAmount,
            uint256 totalDisbursedAmount,
            uint256 totalCharities,
            uint256 platformBalance
        ) 
    {
        return (totalDonations, totalDisbursed, charityCount, address(this).balance);
    }
    
    /**
     * @dev Emergency function to deactivate a charity
     */
    function deactivateCharity(uint256 _charityId) public onlyOwner {
        require(_charityId < charityCount, "Charity does not exist");
        charities[_charityId].isActive = false;
    }
    
    /**
     * @dev Emergency function to reactivate a charity
     */
    function reactivateCharity(uint256 _charityId) public onlyOwner {
        require(_charityId < charityCount, "Charity does not exist");
        charities[_charityId].isActive = true;
    }
}
