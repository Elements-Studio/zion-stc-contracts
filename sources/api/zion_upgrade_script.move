module ZionBridge::zion_upgrade_script {
    use StarcoinFramework::BCS;
    use StarcoinFramework::STC::{Self, STC};
    use StarcoinFramework::Token;
    use StarcoinFramework::TypeInfo;

    use ZionBridge::SafeMath;
    use ZionBridge::zion_cross_chain_manager;
    use ZionBridge::zion_lock_proxy;

    public fun bindAssets(admin: &signer, zion_id: u64) {
        zion_lock_proxy::initTreasury<STC>(admin);
        zion_lock_proxy::bindAsset<STC>(
            admin,
            zion_id,
            BCS::to_bytes(&TypeInfo::type_of<Token::Token<STC::STC>>()),
            SafeMath::log10(Token::scaling_factor<STC>())
        );

        zion_lock_proxy::initTreasury<PolyBridge::XUSDT::XUSDT>(admin);
        zion_lock_proxy::bindAsset<PolyBridge::XUSDT::XUSDT>(
            admin,
            zion_id,
            BCS::to_bytes(&TypeInfo::type_of<Token::Token<PolyBridge::XUSDT::XUSDT>>()),
            SafeMath::log10(Token::scaling_factor<PolyBridge::XUSDT::XUSDT>())
        );

        zion_lock_proxy::initTreasury<PolyBridge::XETH::XETH>(admin);
        zion_lock_proxy::bindAsset<PolyBridge::XETH::XETH>(
            admin,
            zion_id,
            BCS::to_bytes(&TypeInfo::type_of<Token::Token<PolyBridge::XETH::XETH>>()),
            SafeMath::log10(Token::scaling_factor<PolyBridge::XETH::XETH>())
        );
    }

    public entry fun genesis_init(admin: signer, raw_header: vector<u8>, starcoin_zion_id: u64) {
        // Treasury
        zion_cross_chain_manager::init(&admin, raw_header, starcoin_zion_id);

        let license = zion_cross_chain_manager::issueLicense(&admin, @ZionBridge, b"zion_lock_proxy");
        let license_id = zion_cross_chain_manager::getLicenseId(&license);
        zion_lock_proxy::init(&admin);
        zion_lock_proxy::receiveLicense(license);

        // Bind STC
        zion_lock_proxy::bindProxy(&admin, starcoin_zion_id, license_id);
        bindAssets(&admin, starcoin_zion_id);
    }
}
