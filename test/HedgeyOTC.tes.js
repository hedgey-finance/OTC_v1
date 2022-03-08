/**
 * TESTS THAT NEED DO BE RUN FOR THE OTD BLOCK
 * 
 * 1. Test the constructor function - and that it returns the two public values input into the constructor
 * 2. Test the create function - will need several iterations of this:
 *   a) _token is a standard ERC20 and paymentCurrency is a standard ERC20 (with no specific buyer address && unlockDate == 0 && amount = 10 * min)
 *   b) _token is WETH and paymentCurrency is a standard ERC20 (with no specific buyer address && unlockDate == 0 && amount = 10 * min)
 *   c) _token is standard ERC20 and paymentCurrency is WETH (with no specific buyer address && unlockDate == 0 && amount = 10 * min)
 *   d) _token is an ERC20 and paymentCurrency is the same ERC20 as the _token (with no specific buyer address && unlockDate == 0 && amount = 10 * min)
 *   e) _token is WETH and paymentCurrency is WETH (with no specific buyer address && unlockDate == 0 && amount = 10 * min)
 * 
 *   f) _token is a standard ERC20 and paymentCurrency is a standard ERC20 (with A specific buyer address && unlockDate == 0 && amount = 10 * min)
 *   g) _token is WETH and paymentCurrency is a standard ERC20 (with A specific buyer address && unlockDate == 0 && amount = 10 * min)
 *   h) _token is standard ERC20 and paymentCurrency is WETH (with A specific buyer address && unlockDate == 0 && amount = 10 * min)
 *   i) _token is an ERC20 and paymentCurrency is the same ERC20 as the _token (with A specific buyer address && unlockDate == 0 && amount = 10 * min)
 *   j) _token is WETH and paymentCurrency is WETH (with A specific buyer address && unlockDate == 0 && amount = 10 * min) 
 * 
 *   k) _token is a standard ERC20 and paymentCurrency is a standard ERC20 (with no specific buyer address && unlockDate > now && amount = 10 * min)
 *   l) _token is WETH and paymentCurrency is a standard ERC20 (with no specific buyer address && unlockDate > now && amount = 10 * min)
 *   m) _token is standard ERC20 and paymentCurrency is WETH (with no specific buyer address && unlockDate > now && amount = 10 * min)
 *   n) _token is an ERC20 and paymentCurrency is the same ERC20 as the _token (with no specific buyer address && unlockDate > now && amount = 10 * min)
 *   o) _token is WETH and paymentCurrency is WETH (with no specific buyer address && unlockDate > now && amount = 10 * min)
 * 
 *   p) _token is a standard ERC20 and paymentCurrency is a standard ERC20 (with A specific buyer address && unlockDate > now && amount = 10 * min)
 *   q) _token is WETH and paymentCurrency is a standard ERC20 (with A specific buyer address && unlockDate > now && amount = 10 * min)
 *   r) _token is standard ERC20 and paymentCurrency is WETH (with A specific buyer address && unlockDate > now && amount = 10 * min)
 *   s) _token is an ERC20 and paymentCurrency is the same ERC20 as the _token (with A specific buyer address && unlockDate > now && amount = 10 * min)
 *   t) _token is WETH and paymentCurrency is WETH (with A specific buyer address && unlockDate > now && amount = 10 * min)
 * 
 *   ... Retest ALL OF THIS WHERE AMOUNT == MINIMUM
 * 
 * 
 * 
 * 3. Test create function for errors:
 *   a) test for maturity date is less than the current block time stamp - ensure the proper error is recorded
 *   b) test if the amount is < the minimum
 *   c) test for the price == 0
 *   d) test for the minimum == 0
 *   e) test for the minimum to be 1 wei and price to be 1 gwei
 *   f) test for when sending a _token == WETH but sending 1) Too much ETH in msg.value and 2) too little ETH in msg.value
 *   g) test for when sending a _token == ERC20 but the wallet has insufficient balances
 *   h) test if the _token is a 'tax' or 'deflationary' token and the amount delivered in does not match the amount received
 *   i) test if the _token doesn't have a decimals() call function in the ERC20 contract 
 * 
 * 4. Test create to ensure the struct is created properly at the proper index (d)
 *   to test this - will want a state check on the struct Deal at index (d) before create
 *   and then check the state of the Deal struct at index (d) after create has completed 
 *   and ensure that the new state matches what was input into the parameters
 * 
 * 5. Test close function:
 *   a) test what is returned at the index (d) when the storage struct is called
 *   b) test closing a deal where the _token is WETH
 *   c) test closing a deal where the _token is an ERC20
 * 
 *  6. Test close function for errors
 *   a) test what happens when the msg.sender is Not the seller
 *   b) test for when the remaining amount == 0
 *   c) test for when the deal.open == false
 * 
 * 
 *  7. Test the buy function:
 *   a) test what is returned at the index (d) when the storage struct is called
 * 
 *   public version testing with no timelock and minimum < amount
 *   b) test buying the minimum of a deal where the _token is an ERC20 and the paymentCurrency is an ERC20 (deal is public && unlock date == 0 && minimum < amount)
 *   c) test buying the minimum of a deal where the _token is an ERC20 and the paymentCurrency is WETH (deal is public && unlock date == 0 && minimum < amount)
 *   d) test buying the minimum of a deal where the _token is WETH and the paymentCurrency is an ERC20 (deal is public && unlock date == 0 && minimum < amount)
 *   e) test buying the minimum of a deal where the _token is WETH and paymentCurrency is WETH (deal is public && unlock date == 0 && minimum < amount)
 *   f) test buying the minimum of a deal where the _token is an ERC20 and paymentCurrency is the same ERC20 (deal is public && unlock date == 0 && minimum < amount)
 * 
 *    private version testing with no timelock and minimum < amount
 *   g) test buying the minimum of a deal where the _token is an ERC20 and the paymentCurrency is an ERC20 (deal is private && unlock date == 0 && minimum < amount)
 *   h) test buying the minimum of a deal where the _token is an ERC20 and the paymentCurrency is WETH (deal is private && unlock date == 0 && minimum < amount)
 *   i) test buying the minimum of a deal where the _token is WETH and the paymentCurrency is an ERC20 (deal is private && unlock date == 0 && minimum < amount)
 *   j) test buying the minimum of a deal where the _token is WETH and paymentCurrency is WETH (deal is private && unlock date == 0 && minimum < amount)
 *   k) test buying the minimum of a deal where the _token is an ERC20 and paymentCurrency is the same ERC20 (deal is private && unlock date == 0 && minimum < amount)
 * 
 *   public version testing with no timelock and minimum < amount - but we are buying the entire remaining amount
 *   b) test buying the remainingAmount of a deal where the _token is an ERC20 and the paymentCurrency is an ERC20 (deal is public && unlock date == 0 && minimum < amount)
 *   c) test buying the remainingAmount of a deal where the _token is an ERC20 and the paymentCurrency is WETH (deal is public && unlock date == 0 && minimum < amount)
 *   d) test buying the remainingAmount of a deal where the _token is WETH and the paymentCurrency is an ERC20 (deal is public && unlock date == 0 && minimum < amount)
 *   e) test buying the remainingAmount of a deal where the _token is WETH and paymentCurrency is WETH (deal is public && unlock date == 0 && minimum < amount)
 *   f) test buying the remainingAmount of a deal where the _token is an ERC20 and paymentCurrency is the same ERC20 (deal is public && unlock date == 0 && minimum < amount)
 * 
 *    private version testing with no timelock and minimum < amount - but we are buying the entire remaining amount
 *   g) test buying the remainingAmount of a deal where the _token is an ERC20 and the paymentCurrency is an ERC20 (deal is private && unlock date == 0 && minimum < amount)
 *   h) test buying the remainingAmount of a deal where the _token is an ERC20 and the paymentCurrency is WETH (deal is private && unlock date == 0 && minimum < amount)
 *   i) test buying the remainingAmount of a deal where the _token is WETH and the paymentCurrency is an ERC20 (deal is private && unlock date == 0 && minimum < amount)
 *   j) test buying the remainingAmount of a deal where the _token is WETH and paymentCurrency is WETH (deal is private && unlock date == 0 && minimum < amount)
 *   k) test buying the remainingAmount of a deal where the _token is an ERC20 and paymentCurrency is the same ERC20 (deal is private && unlock date == 0 && minimum < amount)
 * 
 * ******************WITH A TIMELOCK************* NEED TO ENSURE THAT THE NFT IS MINTED FOR EACH OF THESE
 * 
 *   public version testing with A timelock and minimum < amount
 *   b) test buying the minimum of a deal where the _token is an ERC20 and the paymentCurrency is an ERC20 (deal is public && unlock date > now && minimum < amount)
 *   c) test buying the minimum of a deal where the _token is an ERC20 and the paymentCurrency is WETH (deal is public && unlock date > now && minimum < amount)
 *   d) test buying the minimum of a deal where the _token is WETH and the paymentCurrency is an ERC20 (deal is public && unlock date > now && minimum < amount)
 *   e) test buying the minimum of a deal where the _token is WETH and paymentCurrency is WETH (deal is public && unlock date > now && minimum < amount)
 *   f) test buying the minimum of a deal where the _token is an ERC20 and paymentCurrency is the same ERC20 (deal is public && unlock date > now && minimum < amount)
 * 
 *    private version testing with A timelock and minimum < amount
 *   g) test buying the minimum of a deal where the _token is an ERC20 and the paymentCurrency is an ERC20 (deal is private && unlock date > now && minimum < amount)
 *   h) test buying the minimum of a deal where the _token is an ERC20 and the paymentCurrency is WETH (deal is private && unlock date > now && minimum < amount)
 *   i) test buying the minimum of a deal where the _token is WETH and the paymentCurrency is an ERC20 (deal is private && unlock date > now && minimum < amount)
 *   j) test buying the minimum of a deal where the _token is WETH and paymentCurrency is WETH (deal is private && unlock date > now && minimum < amount)
 *   k) test buying the minimum of a deal where the _token is an ERC20 and paymentCurrency is the same ERC20 (deal is private && unlock date > now && minimum < amount)
 * 
 *   public version testing with A timelock and minimum < amount - but we are buying the entire remaining amount
 *   b) test buying the remainingAmount of a deal where the _token is an ERC20 and the paymentCurrency is an ERC20 (deal is public && unlock date > now && minimum < amount)
 *   c) test buying the remainingAmount of a deal where the _token is an ERC20 and the paymentCurrency is WETH (deal is public && unlock date > now && minimum < amount)
 *   d) test buying the remainingAmount of a deal where the _token is WETH and the paymentCurrency is an ERC20 (deal is public && unlock date > now && minimum < amount)
 *   e) test buying the remainingAmount of a deal where the _token is WETH and paymentCurrency is WETH (deal is public && unlock date > now && minimum < amount)
 *   f) test buying the remainingAmount of a deal where the _token is an ERC20 and paymentCurrency is the same ERC20 (deal is public && unlock date > now && minimum < amount)
 * 
 *    private version testing with A timelock and minimum < amount - but we are buying the entire remaining amount
 *   g) test buying the remainingAmount of a deal where the _token is an ERC20 and the paymentCurrency is an ERC20 (deal is private && unlock date > now && minimum < amount)
 *   h) test buying the remainingAmount of a deal where the _token is an ERC20 and the paymentCurrency is WETH (deal is private && unlock date > now && minimum < amount)
 *   i) test buying the remainingAmount of a deal where the _token is WETH and the paymentCurrency is an ERC20 (deal is private && unlock date > now && minimum < amount)
 *   j) test buying the remainingAmount of a deal where the _token is WETH and paymentCurrency is WETH (deal is private && unlock date > now && minimum < amount)
 *   k) test buying the remainingAmount of a deal where the _token is an ERC20 and paymentCurrency is the same ERC20 (deal is private && unlock date > now && minimum < amount)
 * 
 * 
 * ***********WITH A TIMELOCK AND AMOUNT == MINIMUM ******** NEED TO ENSURE THAT THE NFT IS MINTED FOR EACH OF THESE
 * 
 *  public version testing with A timelock and minimum == amount
 *   b) test buying the minimum of a deal where the _token is an ERC20 and the paymentCurrency is an ERC20 (deal is public && unlock date > now && minimum == amount)
 *   c) test buying the minimum of a deal where the _token is an ERC20 and the paymentCurrency is WETH (deal is public && unlock date > now && minimum == amount)
 *   d) test buying the minimum of a deal where the _token is WETH and the paymentCurrency is an ERC20 (deal is public && unlock date > now && minimum == amount)
 *   e) test buying the minimum of a deal where the _token is WETH and paymentCurrency is WETH (deal is public && unlock date > now && minimum == amount)
 *   f) test buying the minimum of a deal where the _token is an ERC20 and paymentCurrency is the same ERC20 (deal is public && unlock date > now && minimum == amount)
 * 
 *    private version testing with A timelock and minimum < amount
 *   g) test buying the minimum of a deal where the _token is an ERC20 and the paymentCurrency is an ERC20 (deal is private && unlock date > now && minimum == amount)
 *   h) test buying the minimum of a deal where the _token is an ERC20 and the paymentCurrency is WETH (deal is private && unlock date > now && minimum == amount)
 *   i) test buying the minimum of a deal where the _token is WETH and the paymentCurrency is an ERC20 (deal is private && unlock date > now && minimum == amount)
 *   j) test buying the minimum of a deal where the _token is WETH and paymentCurrency is WETH (deal is private && unlock date > now && minimum == amount)
 *   k) test buying the minimum of a deal where the _token is an ERC20 and paymentCurrency is the same ERC20 (deal is private && unlock date > now && minimum == amount)
 * 
 *   public version testing with A timelock and minimum < amount - but we are buying the entire remaining amount
 *   b) test buying the remainingAmount of a deal where the _token is an ERC20 and the paymentCurrency is an ERC20 (deal is public && unlock date > now && minimum == amount)
 *   c) test buying the remainingAmount of a deal where the _token is an ERC20 and the paymentCurrency is WETH (deal is public && unlock date > now && minimum == amount)
 *   d) test buying the remainingAmount of a deal where the _token is WETH and the paymentCurrency is an ERC20 (deal is public && unlock date > now && minimum == amount)
 *   e) test buying the remainingAmount of a deal where the _token is WETH and paymentCurrency is WETH (deal is public && unlock date > now && minimum == amount)
 *   f) test buying the remainingAmount of a deal where the _token is an ERC20 and paymentCurrency is the same ERC20 (deal is public && unlock date > now && minimum == amount)
 * 
 *    private version testing with A timelock and minimum < amount - but we are buying the entire remaining amount
 *   g) test buying the remainingAmount of a deal where the _token is an ERC20 and the paymentCurrency is an ERC20 (deal is private && unlock date > now && minimum == amount)
 *   h) test buying the remainingAmount of a deal where the _token is an ERC20 and the paymentCurrency is WETH (deal is private && unlock date > now && minimum == amount)
 *   i) test buying the remainingAmount of a deal where the _token is WETH and the paymentCurrency is an ERC20 (deal is private && unlock date > now && minimum == amount)
 *   j) test buying the remainingAmount of a deal where the _token is WETH and paymentCurrency is WETH (deal is private && unlock date > now && minimum == amount)
 *   k) test buying the remainingAmount of a deal where the _token is an ERC20 and paymentCurrency is the same ERC20 (deal is private && unlock date > now && minimum == amount)
 * 
 * 
 *   8. Test the buy function for errors: 
 *     a) Test buying where the msg.sender is the seller
 *     b) test buying where the deal.open == false
 *     c) test buying where the deal.maturity is < now
 *     d) test buying where the deal.buyer is a private wallet and we are buying with Not that wallet
 *     e) test buying where the amount to be purchased is less than the deal.minimumPurchase but != deal.remainingAmount
 *     f) test buying where the amount to be purchased  is greater than the deal.remainingAmount
 *     g) test byuing where the wallet has insufficient balance to make the purchase
 * 
 */
