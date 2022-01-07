# OTC_Core
Core solidity build for OTC products

How the OTC Works:

A seller of a token can put their tokens up for sale via a peer to peer OTC sale.
They can sell their tokens in a single chunk to an individual buyer, or they can sell tokens in bulk as a pool, and let any buyers buy from that pool.
The seller can also set a timelock on the tokens that are purchased. IF the timelock unlock date is beyond the time when a buyer purchases the tokens, then an NFT is generated to record the timelock position. 
The NFT is then minted to the owner of the locked tokens, whereupon after the time has passed and the tokens are unlocked, the owner can redeem their NFT, burning it in the contract and thus redeeming / withdrawing their locked tokens from escrow to their account. 

Mechanically the NFT contract is owned by the OTC Sale contract so that ONLY the OTC Sale contract can mint a new NFT.
This prevents any situation where someone tries to mint an NFT without depositing the proper tokens and therefore creates a break in the code. 
