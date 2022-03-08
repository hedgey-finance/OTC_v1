/**
 * TESTING SCHEDULE
 * 
 * 
 *  1. Test the constructor - ensure the inputs match what is stored on the deployed contract
 * 
 *  2. Test the transferOwnership function for before and after state - and that the after state matches the new owner
 * 
 *  3. Test the transferOwnership function for errors:
 *   a) Test with the owner transferring the ownership to a new wallet
 *    ... then test with that same former owner trying to transfer ownership again (should get a failure)
 *   b) test transferring owner to another private wallet - and then with the new private wallet owner, test transferring ownership back
 *   ... this is testing that the ownerSet variable forces teh error Owner already set
 *   c) test transferring ownership to the Zero address to force the error
 * 
 *   4. Test the updateBaseURI function for the before and after state - and ensure after state matches the new URI
 * 
 *   5. Using the OTC testing - test and evaluate creating futures, ensure that data passed from the OTC matches with what is 
 *      intended to be created:
 *      a) ensure the correct buyer from the OTC is minted the NFT (ie that buyer is the after state owner of this NFT)
 *      b) ensure the struct created matches the details passed into the function for the amount, asset, and expiry
 *      c) ensure that the amount of tokens delivered from the OTC contract match perfectly to the amount and type of tokens stored in the new struct
 * 
 *   6. Test redeem function
 *     a) Test redeeming an unlocked future NFT to ensure that the event is emitted, the tokens are withdrawn to the owner, and the NFT and struct are deleted
 *   
 *    7. Test reedeem function for errors:
 *     a) Test calling the function for an NFT that you are not the owner of
 *     b) test calling the function for an NFT you are the owner of, but the expiry date is still in the future
 * 
 */
