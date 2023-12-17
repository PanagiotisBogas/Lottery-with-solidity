// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

contract Lottery {

    struct Person{
        uint personId;
        address addr;
        uint remainingTokens;    
    }

    struct Item{
        uint itemId;
        address[] itemTokens;
        address winner;    
    }

    enum Stage {Init, Reg, Bid, Done}
    Stage public stage;
    event Winner(address winner,  uint itemId);
    mapping(address => Person) public  tokenDetails; // διεύθυνση παίκτη
    Person [] public bidders;
    Item [] public items;
    
    address[] public winners; // πίνακας νικητών - η τιμή 0 δηλώνει πως δεν υπάρχει νικητής
    address public beneficiary; // ο πρόεδρος του συλλόγου και ιδιοκτήτης του smart contract
    uint bidderCount = 1; // πλήθος των εγγεγραμένων παικτών
    uint itemCount = 0; // πλήθος των item
    address[] emptyArray;
    address emptyAddr;

    constructor() payable{ //constructor 
        // Αρχικοποίηση του προέδρου με τη διεύθυνση του κατόχου του έξυπνου συμβολαίου 
        beneficiary = msg.sender;  
        stage == Stage.Init;
    }

    //This modifier allows a function to be called only by the deplyer of this contract
    modifier onlyOwner(){
        require(msg.sender == beneficiary, "Only the beneficiary is allowed to use this function");
        _;
    }

    //This modifier does not allow a function to be called by the deplyer of this contract
    modifier onlyBidders(){
        require(msg.sender != beneficiary, "beneficiary not allowed to use this function");
        _;
    }

    // The bidder has to have 0.005 ETH in order to register for the lottery
    modifier bidderFundsCheck(){
         require(msg.value >= 5000000000000000, "Not enough WEI");
        _;
    }

   //A modifier that requires the msg.sender to be non existant to the tokenDetails mapping
   modifier bidderNotRegistered(){
         require(tokenDetails[msg.sender].addr != msg.sender, "Allready Registered");
        _;
    }

    //A modifier that checks if the msg.sender is registered as a bidder
    modifier bidderIsRegistered(){
         require(tokenDetails[msg.sender].addr == msg.sender, "Not Registered");
        _;
    }

    // A modifier that checks if the bidder has enough tokens 
    modifier bidderHasEnoughTokens(){
         require(tokenDetails[msg.sender].remainingTokens >=1 , "Not enough tokens");
        _;
    }

    modifier regStage(){
        require(stage == Stage.Reg, "At this stage only registration is allowed");
        _;
    }

    modifier bidStage(){
        require(stage == Stage.Bid, "At this stage only bidding is allowed");
        _;
    }

    modifier doneStage(){
        require(stage == Stage.Done,  "Registration and bidding stage has ended. Time to reveal the winners");
        _;
    }

    //This function creates new items
    function addItems()   public  onlyOwner{ 
        items.push(Item({itemId:itemCount, itemTokens:emptyArray, winner:emptyAddr})); //create item
        itemCount++;
    }

    //Bidders call this function to register for  the lottery and receive tickets. Every bidder can only register once and receive 5 tickets
    function register() public payable bidderFundsCheck onlyBidders bidderNotRegistered regStage{ // εγγραφή παίκτη 
        bidders.push(Person({personId:bidderCount, addr:msg.sender, remainingTokens:5})); //create item 
        tokenDetails[msg.sender] = bidders[bidderCount-1]; 
        bidderCount++; 
    }

    //This function gets the contracts balance
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    // This function generates a pseudorandom number
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, bidders.length)));
    }

    function bid(uint _itemId, uint _count) public payable onlyBidders bidderHasEnoughTokens bidderIsRegistered bidStage{ // Ποντάρει _count λαχεία στο αντικείμενο _itemId 
         
        require(items[_itemId].itemId == _itemId, "Item does not exist");
        require(tokenDetails[msg.sender].remainingTokens >= _count, "Not enough tokens");

        tokenDetails[msg.sender].remainingTokens -= _count;

        for(uint i =0; i<_count; i++){
            items[_itemId].itemTokens.push(msg.sender);
        }
        
    }
    
    
    function revealWinners(uint _itemNum) public onlyOwner doneStage{
            require(items[_itemNum].itemTokens.length > 0);
            require(items[_itemNum].winner == emptyAddr);

            uint  r= random();
            uint index;
            address winner = emptyAddr;

            if ((items[_itemNum].itemTokens.length > 0) && (items[_itemNum].winner == emptyAddr)) {  
                index = r % items[_itemNum].itemTokens.length;
                winner = items[_itemNum].itemTokens[index];
                items[_itemNum].winner = winner;
                winners.push(winner);
            }else {
                winners.push(emptyAddr);
            }

            emit Winner(winner, items[_itemNum].itemId);

    }
    
    //The contract owner can withdraw the contract's funds to his wallet
    function withdraw() public onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }


    //The contract owner can "clear" the items, bidders and winners arrays
    function reset() public onlyOwner{

        stage == Stage.Reg;

        for (uint i = 0; i<items.length; i++) 
        {
            items.pop();
        }

        for (uint i = 0; i<bidders.length; i++) 
        {
            bidders.pop();
        }

        for (uint i = 0; i<winners.length; i++) 
        {
            winners.pop();
        }

    }

    function advanceState() public onlyOwner{
        if (stage == Stage.Init) {stage = Stage.Reg; return;}
        if (stage == Stage.Reg) {stage = Stage.Bid; return;}
        if (stage == Stage.Bid) {stage = Stage.Done; return;}
    }




}