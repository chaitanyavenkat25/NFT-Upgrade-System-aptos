module MyModule::NFTUpgrade {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    struct UpgradeableNFT has store, key {
        level: u64,           
        power: u64,          
        upgrade_cost: u64,
    }
    const E_INSUFFICIENT_FUNDS: u64 = 1;
    const E_NFT_NOT_FOUND: u64 = 2;
    const E_MAX_LEVEL_REACHED: u64 = 3;
    const MAX_LEVEL: u64 = 10;
    public fun mint_nft(owner: &signer, initial_power: u64) {
        let nft = UpgradeableNFT {
            level: 1,
            power: initial_power,
            upgrade_cost: 100,
        };
        move_to(owner, nft);
    }

    /// Function to upgrade an existing NFT using AptosCoin
    public fun upgrade_nft(
        owner: &signer, 
        nft_owner: address
    ) acquires UpgradeableNFT {
        // Check if NFT exists
        assert!(exists<UpgradeableNFT>(nft_owner), E_NFT_NOT_FOUND);
        
        let nft = borrow_global_mut<UpgradeableNFT>(nft_owner);
        
        // Check if NFT can be upgraded further
        assert!(nft.level < MAX_LEVEL, E_MAX_LEVEL_REACHED);
        
        // Check if owner has sufficient funds
        let owner_balance = coin::balance<AptosCoin>(signer::address_of(owner));
        assert!(owner_balance >= nft.upgrade_cost, E_INSUFFICIENT_FUNDS);
        
        // Withdraw upgrade cost from owner
        let payment = coin::withdraw<AptosCoin>(owner, nft.upgrade_cost);
        
        // For simplicity, burn the payment (in real scenario, could go to treasury)
        coin::destroy_zero(coin::zero<AptosCoin>());
        coin::destroy_burn_cap(coin::extract_burn_cap<AptosCoin>(payment));
        
        // Upgrade the NFT
        nft.level = nft.level + 1;
        nft.power = nft.power + (nft.level * 10); // Power increases based on level
        nft.upgrade_cost = nft.upgrade_cost + (nft.level * 50); // Cost increases with level
    }
}