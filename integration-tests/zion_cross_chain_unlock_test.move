//# init -n test --public-keys ZionBridge=0x8085e172ecf785692da465ba3339da46c4b43640c3f92a45db803690cc3c4a36

//# faucet --addr Bridge --amount 10000000000

//# faucet --addr alice --amount 10000000000000000

//# faucet --addr bob --amount 10000000000000000


//# run --signers Bridge
script {
    use ZionBridge::zion_cross_chain_utils;

    fun test_check_header(_signer: signer) {
        // https://explorer.aptoslabs.com/txn/411144842/payload
        let raw_header = x"f90253a026532dd944a45455ea77d854cafa63e6da550d7a99bc022742d7a9c0eb30b695a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347948c09d936a1b408d6e0afaa537ba4e06c4504a0aea076076b2ef9012a600c981222e59820dd9713ac815f4a8a12740f7f719ab4e274a0624b8b1a16d1c095acad3d96ed588d0702fcde91db52aad4deb77f882b0ef300a0d4e4d938901e00ea4da08917593dba522a19b68413162444389bb35251dd96e3b9010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018275308411e1a30083029bf884641a7a0fb8810000000000000000000000000000000000000000000000000000000000000000f85f82753082ea60f85494258af48e28e4a6846e931ddff8e1cdf8579821e5946a708455c8777630aac9d1e7702d13f7a865b27c948c09d936a1b408d6e0afaa537ba4e06c4504a0ae94ad3bf5ed640cc72f37bd21d64a65c3c756e9c88c80c08008";
        let (_, _) = zion_cross_chain_utils::decode_header(&raw_header);
        let (_, _) = zion_cross_chain_utils::decode_extra(&raw_header);
    }
}
// check: EXECUTED

//# run --signers Bridge
script {
    use ZionBridge::SafeMath;
    use ZionBridge::zion_cross_chain_manager;
    use ZionBridge::zion_lock_proxy;
    use StarcoinFramework::BCS;
    use StarcoinFramework::STC::STC;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Token;
    use StarcoinFramework::TypeInfo;

    fun test_genesis_initialize(signer: signer) {
        let starcoin_poly_id = 318; // The poly id of aptos is 998, because the test data was from aptos

        // https://explorer.aptoslabs.com/txn/411144842/payload
        let raw_header = x"f90253a026532dd944a45455ea77d854cafa63e6da550d7a99bc022742d7a9c0eb30b695a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347948c09d936a1b408d6e0afaa537ba4e06c4504a0aea076076b2ef9012a600c981222e59820dd9713ac815f4a8a12740f7f719ab4e274a0624b8b1a16d1c095acad3d96ed588d0702fcde91db52aad4deb77f882b0ef300a0d4e4d938901e00ea4da08917593dba522a19b68413162444389bb35251dd96e3b9010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018275308411e1a30083029bf884641a7a0fb8810000000000000000000000000000000000000000000000000000000000000000f85f82753082ea60f85494258af48e28e4a6846e931ddff8e1cdf8579821e5946a708455c8777630aac9d1e7702d13f7a865b27c948c09d936a1b408d6e0afaa537ba4e06c4504a0ae94ad3bf5ed640cc72f37bd21d64a65c3c756e9c88c80c08008";
        zion_cross_chain_manager::init(&signer, raw_header, starcoin_poly_id);

        let license = zion_cross_chain_manager::issueLicense(&signer, Signer::address_of(&signer), b"zion_lock_proxy");
        let license_id = zion_cross_chain_manager::getLicenseId(&license);

        zion_lock_proxy::init(&signer);
        zion_lock_proxy::initTreasury<STC>(&signer);
        zion_lock_proxy::receiveLicense(license);

        // Bind STC
        zion_lock_proxy::bindProxy(&signer, starcoin_poly_id, license_id);
        zion_lock_proxy::bindAsset<STC>(
            &signer,
            starcoin_poly_id,
            BCS::to_bytes(&TypeInfo::type_of<STC>()),
            SafeMath::log10(Token::scaling_factor<STC>())
        );
    }
}
// check: EXECUTED

//# run --signers Bridge
script {
    use ZionBridge::zion_cross_chain_manager;

    const ZION_SEAL_RLP_LEN: u64 = 67;

    fun test_relayer_change_epoch_1(sender: signer) {
        // Raw header from https://explorer.aptoslabs.com/txn/484547462/payload, next from the data using in `init` function
        let raw_header_1 = x"f90254a05184b372e6ae2815773ca979bd704b19c2e7b6ef01b35bf3640d3d1b009dee14a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347948c09d936a1b408d6e0afaa537ba4e06c4504a0aea0a26ab86306f1badbc85c923b920f550ffcce2789d991b9c4de0af78b30f14d76a0656c17096ddb120cd3ea99f6fb3395a64545eb720405215b696a42f60b43fecda0d4e4d938901e00ea4da08917593dba522a19b68413162444389bb35251dd96e3b90100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000182ea608411e1a30083029bf884641bd99fb8820000000000000000000000000000000000000000000000000000000000000000f86082ea6083015f90f85494258af48e28e4a6846e931ddff8e1cdf8579821e5946a708455c8777630aac9d1e7702d13f7a865b27c948c09d936a1b408d6e0afaa537ba4e06c4504a0ae94ad3bf5ed640cc72f37bd21d64a65c3c756e9c88c80c08008";
        let raw_seals_1 = x"f8c9b841586c4d011be6f882ba544427c080ea2751f9e09fc51efbe7ea8a806375c1620d1945d567745c764a0b34579b03deb4c7dd12c7e1e18ddb8f9036234b32cf5c1800b841e110a83049be8212a0ec0cbf0bf83666acf128890b5fb7e1bf7e7002d9ebcac96ebab318bb1d46ba14208d016c42fc00e71bb81efd7be32be6b3a1bcb9fb488200b8414be6409d965f388e8e02d49db2468e621edd15bf637046f408a63b4a75c48831586ed2cf2246f27b09224ac7a1c2c7c5cea8d5fdda62cf5489954dd2855be7de00";
        zion_cross_chain_manager::change_epoch(&sender, &raw_header_1, &raw_seals_1);

        // Raw header from https://explorer.aptoslabs.com/txn/484547485/payload, next from the data using in `init` function
        let raw_header_2 = x"f90256a0a2de37b26d37809c018ba29de7b0c2b59dd5d0140305f331f83dc523576b6f21a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347948c09d936a1b408d6e0afaa537ba4e06c4504a0aea026221f12fa77e6355de657c933bb4ef1e579e04c129e863ee6b510163431d20ba0cc566bb4aff22e12218d0fe2c06bd3e4fbf39a2c2510483cd7b9e12c5a54cfd6a0d4e4d938901e00ea4da08917593dba522a19b68413162444389bb35251dd96e3b90100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000183015f908411e1a30083029bf884641d392fb8830000000000000000000000000000000000000000000000000000000000000000f86183015f908301d4c0f85494258af48e28e4a6846e931ddff8e1cdf8579821e5946a708455c8777630aac9d1e7702d13f7a865b27c948c09d936a1b408d6e0afaa537ba4e06c4504a0ae94ad3bf5ed640cc72f37bd21d64a65c3c756e9c88c80c08008";
        let raw_seals_2 = x"f8c9b8416ab992f338050ec4469c70a97a5f465d0e5c01d1bcdb0d339bf1cb6876d3d6e25f202aad085db2138cdc19ee311d295a843ec431f2d1cf4eaf7d677aa3d6157b00b8414dc38730d350518db7e5e828ae7c33eb032f3f00f66b545e6cbf6edcd3c7475337dbf366b9419d911f8b26a71e73a330ffb35c0a1a8a932c6ea87ed225e8851900b8416eb3e1028108a663728f419f4ec6275b41fa5921b6e92965ed1841ee958586d80415baf6e1fbc0d10939bfc21c0525f51e821d2100a5d76dc3bc42d22ba6be6d01";
        zion_cross_chain_manager::change_epoch(&sender, &raw_header_2, &raw_seals_2);

        // Raw header from https://explorer.aptoslabs.com/txn/484547519/payload, next from the data using in `init` function
        let raw_header_3 = x"f90256a075477314f78387e44cb6e27d032aef661bbedf7892596e4ffcc82f46390f4f1ca01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347948c09d936a1b408d6e0afaa537ba4e06c4504a0aea0797c2dd68b45da600f04414d4208164de3d965ff3b35d915748f1ab70ec0d616a0d3e4d0012686c3b13ce2002f51242faf5d44846b440e59d94c1d6347d1372d71a0d4e4d938901e00ea4da08917593dba522a19b68413162444389bb35251dd96e3b9010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018301d4c08411e1a30083029bf884641e98bfb8830000000000000000000000000000000000000000000000000000000000000000f8618301d4c0830249f0f85494258af48e28e4a6846e931ddff8e1cdf8579821e5946a708455c8777630aac9d1e7702d13f7a865b27c948c09d936a1b408d6e0afaa537ba4e06c4504a0ae94ad3bf5ed640cc72f37bd21d64a65c3c756e9c88c80c08008";
        let raw_seals_3 = x"f8c9b841dd0ef7fbb34b3f247fdf76d508952a1b604d2d9277500eba7705135334a09ec2599010cfb813d3efe640f48c13ff1bc5e9a559d8ec9cc0837ed86bcb0435c76100b8410346317bafc564b3ba8228fda5dc19b8b3347a4e27501a02369e07da4f8661b44871c2986e4d7fefcf23d203f655245b16e11b454a5a6d98ac030abd6b4539e900b841fa21887d66f7460cd88bce216a4bbb5957e21bb86ee6a58baa2869cc5e49644e727100a19c067233b18dd901faeb8d67936b50d5268ee33b85750317e502b7a600";
        zion_cross_chain_manager::change_epoch(&sender, &raw_header_3, &raw_seals_3);

        // Raw header from https://explorer.aptoslabs.com/txn/484547560/payload, next from the data using in `init` function
        let raw_header_4 = x"f90256a04675187f26b642f6f438a8340ad5ee9f95ec9f083602f900f07af502ab52261ca01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347948c09d936a1b408d6e0afaa537ba4e06c4504a0aea0376d5347c60944a0eaccde9365716403e0fee2bf32eb70df10279199636db76ea080c955e3ca2352cad17ae6ea4f43260a194fcf9583d3beca06654566c0c03269a0d4e4d938901e00ea4da08917593dba522a19b68413162444389bb35251dd96e3b901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001830249f08411e1a30083029bf884641ff84fb8830000000000000000000000000000000000000000000000000000000000000000f861830249f08302bf20f85494258af48e28e4a6846e931ddff8e1cdf8579821e5946a708455c8777630aac9d1e7702d13f7a865b27c948c09d936a1b408d6e0afaa537ba4e06c4504a0ae94ad3bf5ed640cc72f37bd21d64a65c3c756e9c88c80c08008";
        let raw_seals_4 = x"f8c9b8416af6dffecedf46d015f428bd18a06733469ed7f5a39c40f369e94960f8d13d7a48e3c1a1fa486de815cd167dba31bfef632c9020b7e286eac3d71e90d2c2e45200b8419378066821695c772678988f6f22cc125dd90111726dae929549551c6c535bdc37cd738fa307ec0855e9d7b504dcfd9e0a0a16fff1bd743bd17aada49c9a0bba00b8419b8a1627c5e135d2187b70e39148375b90e0d9a8b51acb4209006165d9a33fa16c9ffba34d26758ef378a6752023ecac3b8eb99f3a93eb4032f430d2ad8c3fb700";
        zion_cross_chain_manager::change_epoch(&sender, &raw_header_4, &raw_seals_4);

        // Raw header from https://explorer.aptoslabs.com/txn/484547594/payload, next from the data using in `init` function, height: 180,000
        let raw_header_5 = x"f90256a008fd42c436c1cdbf2a055893d9bff8eab3e00edaf18bfd9bff175412b25957a7a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794258af48e28e4a6846e931ddff8e1cdf8579821e5a0ff61fd07cb1f03fc424167649803b0560fe94b39965990600b04e0b75322f94ea0326dd92ff8750d884154e316bf39ad862c78b29b1c49be84f2775c9147083039a0d4e4d938901e00ea4da08917593dba522a19b68413162444389bb35251dd96e3b9010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018302bf208411e1a30083029bf884642157dfb8830000000000000000000000000000000000000000000000000000000000000000f8618302bf2083033450f85494258af48e28e4a6846e931ddff8e1cdf8579821e5946a708455c8777630aac9d1e7702d13f7a865b27c948c09d936a1b408d6e0afaa537ba4e06c4504a0ae94ad3bf5ed640cc72f37bd21d64a65c3c756e9c88c80c08008";
        let raw_seals_5 = x"f8c9b8412190b8292da06a648dbb81bb0e64f01fcb32346b73b15dcef524e4afe0c44166629955b196c95ffc0953ff4ebd7bfee0c4c9ee36d2b7391f1e34110fbc0f691a00b84173a6e74b6b4fb7712e7d485e36886ec966d2e3c69ad247c78e299f643a9746120178667132f2979b15f324d83f3f5ddad22c38e7035324b2bb0d14a2bbc699b701b841dd236e13567209c243005fd34dc17a015aaa808195c77865e83fe686b53e28371881279926227cbdd816083eaa98b97c0a43c9fa5876f6ee27a59e5048aca9fe01";
        zion_cross_chain_manager::change_epoch(&sender, &raw_header_5, &raw_seals_5);

        // From relayer height: 210,000
        let raw_header_6 = x"f90256a007262c343f00ae5c61e24423d10eabc1b54af4119452030f722ea5abec393d79a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794ad3bf5ed640cc72f37bd21d64a65c3c756e9c88ca09aa85a08fd27f5f03a905d51b84b8757f58129297952c4b9ff13f75a8954d38ba0e8527564159e01ceba584567ff9e106af00529c2277243af9019dbb98b899d8da0d4e4d938901e00ea4da08917593dba522a19b68413162444389bb35251dd96e3b901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001830334508411e1a30083029bf8846422b76fb8830000000000000000000000000000000000000000000000000000000000000000f861830334508303a980f85494258af48e28e4a6846e931ddff8e1cdf8579821e5946a708455c8777630aac9d1e7702d13f7a865b27c948c09d936a1b408d6e0afaa537ba4e06c4504a0ae94ad3bf5ed640cc72f37bd21d64a65c3c756e9c88c80c08008";
        let raw_seals_6 = x"f8c9b84164fe8c013a60305a724ecfeb7cef2cb08e3fd5e81dcd626453a7aa718ad7aefa7d61021973815c388febd7fbe8bfefd7056fa6aa90cd71c3df6ddcc35afa61fd01b84185e9e9f5192f6d2575a7715d766798983e2182d7dd50f4fe4abd7f66686e60761deac8f850ceaac1db8736d2d8e32aead301e1edac4c4f9a388ec428cd5730f800b8414c034e8884b5dcb6fc251023aafb2ea6286f2e21239cf14b8c581144551828a81769fbc3e4b4123a6614be49538fac10aa4fa5763af11b93ff26a5a348fa5b0700";
        zion_cross_chain_manager::change_epoch(&sender, &raw_header_6, &raw_seals_6);

        // From relayer height: 240,000
        let raw_header_7 = x"f90256a08452a403cb11307b7b063282f6a11cfc07f6b3eb05be589d7be718157ad0683ca01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794ad3bf5ed640cc72f37bd21d64a65c3c756e9c88ca0ddd5247d0ec5611e6d98774b1d28ee1610b500e2ea7ba80080b1d525554f23c4a07661ee324682ab19b668ef2d3c4cd1dcf42c3610ef5b43320f97b293b3789a2aa0d4e4d938901e00ea4da08917593dba522a19b68413162444389bb35251dd96e3b9010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018303a9808411e1a30083029bf884642416ffb8830000000000000000000000000000000000000000000000000000000000000000f8618303a98083041eb0f85494258af48e28e4a6846e931ddff8e1cdf8579821e5946a708455c8777630aac9d1e7702d13f7a865b27c948c09d936a1b408d6e0afaa537ba4e06c4504a0ae94ad3bf5ed640cc72f37bd21d64a65c3c756e9c88c80c08008";
        let raw_seals_7 = x"f8c9b8417ddf8afa668180da9190f91deea044516ba19c1886dd48af1b4569872c96d300092559f26a349a82e4c091722fe34625b9bcfbee960497b7d9650f0bdef4cdc001b841ff4b10b79c129cf33388042f6f05ad77dfed6780008217290fa6cd14098d820b374a20857ae9a8db5050d328179c7a4d041e785c98b2ce08a2c3136588976d7b00b8411f714f9f91c0829d0fb09a94b60bd06276bae4a8df441b5f819e41a798088a14191b84e3aa61dfe6e395ca60e9d0bcb985b6c936c5da6da3e53c772e7b6491c201";
        zion_cross_chain_manager::change_epoch(&sender, &raw_header_7, &raw_seals_7);
    }
}
// check: EXECUTED

//# run --signers alice
script {
    use ZionBridge::zion_lock_proxy;
    use StarcoinFramework::Account;
    use StarcoinFramework::BCS;
    use StarcoinFramework::STC::STC;
    use StarcoinFramework::Token;

    fun alice_lock_stc(sender: signer) {
        let to_chain_id = 318;
        let amount = 100 * Token::scaling_factor<STC>();
        let stc = Account::withdraw<STC>(&sender, amount);
        let dst_addr = BCS::to_bytes<address>(&@ZionBridge);
        zion_lock_proxy::lock<STC>(&sender, stc, to_chain_id, &dst_addr);
        assert!(zion_lock_proxy::getBalance<STC>() == amount, 10001);
    }
}
// check: EXECUTED

//# run --signers Bridge
script {
    use ZionBridge::zion_lock_proxy;
    use StarcoinFramework::STC::STC;

    fun bridge_unlock_to_bob(sender: signer) {
        let raw_header = x"f901ffa081f4657b97d24e2921eab4168940fb03c9e0a0db863037736347f1df1e6cca08a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794258af48e28e4a6846e931ddff8e1cdf8579821e5a0b184434d3564604453a9cf8f8de9606854a0ee981240ab8d0d3250fed227c2d8a0f5a5579fb689f0c6b349790c2e19f0f130a123ded9c27baac26519bb7ec319b2a0d4e4d938901e00ea4da08917593dba522a19b68413162444389bb35251dd96e3b901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001830415628411e1a30083029bf88464255aa5ad0000000000000000000000000000000000000000000000000000000000000000cc8303a98083041eb0c080c08008";
        let raw_seals = x"f8c9b8419623f297371074824e7c0f0ca43c255af1fe8d703fa1006cdaa1f90e34efda4e7d238271e451b202b8f2dbb8c59fbe4fe8ffe5443bd58c4bf60ea7c1842312d300b84161142b1058fba4b833c710e12fc5472b60d28570c9281ae0fbb6826ea019548c07ee06f2eafe2e95086e8b83e8cd56cb9cd6b9794a0d97ff6fa4b07e68fe0bc100b841f375e01084a6480dec664205795348340e5c957a1081b0e5dd1950850a44795959be8b7e044022f9214bef4264695a474ef53f4da84f701ef3738e4c36236f9c01";
        let account_proof = x"b90372f90211a013969ca86df0f575060d47e6f8cda5a2f3f63066c4d421118ad0d5a9c58ee179a026e1b0a18056707c948169ba4cb75c6db9c43056b8a5d632d71b65dc99f25659a0f4867559e5b7bfde3be3d51217fa1a64bdc06b438ddd47f79032a93482222274a009d6efbadc392309d3303fafadb1b864588cde04cf3bad47a8dde5a4b9e04e85a08d643a1b4b48b84cc879ddee6e76918513f6137aca8146c40d8a6ca3df6f51f4a09f63eac1b8cb522fd99dba56a083176e25faa786850f499f9037dcc5664f541fa079bea5af8c0aa887f5b8e4f6c6fed589d5849731cd3c7a77cb934711bab50829a014c109614176c77cf7894c959757378e00c7449e9d2080005cb1d7d045fcb999a01daedd0c3851e9bd63fd02bd49b46f5e3ecc142b08a281052c006fb0033d4af5a087b4f2d12570c4bb023169ae4b15e583c0db45dadf70be4cf366873a9f2f078da0704f00a377241f5c392e4dda69e1d5c9f578abb51e4d20555a699055e9964967a008cd6b87308c462301de4459e4a09a3b263fb680cabe0403a30e1ff43d48671fa08716cd63019922f747ad7c08c406d0d0eba6d39c9416053e3a03f5fb602231e8a09f422e7a82ac277ab0f8706aa2e41a99086185f5108ba1cc9bd86f8ccc086be1a0ce14f84a1eb83650e36b5e80cffde70c3993ffe9766f5fe237e6c5c05e987056a04467acb98aa93c661a3709dc886f314f38154344ec0c6d6663b430a7dbe0da1f80f8f18080a0f292918ee93d85d7443fb412153ef2ad320f6aedc3bfe0f314410e93ef3036a4a05fe2087d333e4e33cfaa52da5538e48ca395b899ea4109eb2fa5e29d0eb5b39c80808080a05c110a3c814a301c0f2d1cf1bfb7a02f4e87afd1cc56cd4e54f4a4b88ab0e7ff8080a097a227d8068d3b1986cb5a481fa8f3eb8b2eff019949e48dcc0faa7e331b48a1a05bae4d5b69c51dc13d13585eccaa6ace01883b72ecf6af1ef1973553854fab5880a072c8c70ccad3959e464a2b9eda140f01821270e8d927e20d50556398f1d0d822a0246dc51fde3e06d3690060cb37446dbeccdd529424e00f0c2fe8616fa2525e9980f869a02074e65ccffb133d9db4ff637e62532ef6ecef3223845d02f522c55786782911b846f8440180a0d0772eb168f4de30e7153da8fab511abc73bd64c18ce8c90ea69e9cbdd3f1269a0c874e65ccffb133d9db4ff637e62532ef6ecef3223845d02f522c55786782911";
        let storage_proof = x"b9024cf90171808080a0c04df9a1462f85f4763f60f0e03e1876726ad3e85dfd5747e9354fd9b688320da0bc876a50518e00ed79ee7da77ba8d2734f9eef7eb164a3d3bba48d16bbd37adf80a0da2d842ae79147a4af807985afc19940522c9e5f4e588d5296b5a2152d644dd7a03f93e8616276b46214908e3812ed94f677702cf4d4348716b63516c51575ac67a07939a2153da98396d256ec70ebe7aea702eec8a1a28a10846290c56d3617bcbaa0373792e184e3aab113b241fb919c544e70463f1d832655b7b4b597cf52daf71ca0ea68c01ecd031b1827b884fa0247b34de1c3be6db4c80929e07ebd15934d8275a0d7b3b5e741c5e75fe0334744360cc48b2b7a2b9b9896c33dcfacf311a039bd4e80a03183a313ae1b770de6f6883a9197b9b945990cdb3ebdce5fe55f8b4cca0a0d92a00e949eb6a255addbd6289b2974e70e7877e940846365861e45f837a76d3bb619a027d0d1ef2caed5e182b3179fd5c95afb82c335c58991a360059c832febb4db4c80f891808080a02ee37464fbbf6eba3fab4d0d14f16fc5c28f0f6f11f3bb313700fcfb5e3fce438080808080808080a02412d75a8c9c15b8d1271792f8941b9634c6b38409e158722619628c03830820a095dd26741cacd23d8ed5841a744486122ceda636857b13ee4e35061f562adc4180a0b78e86127970b25a99afe67f111d17cccca098817af9310c2f4c32754d95bfd380f843a02054c5726ef02748d55771b81cecc24d5efa556d8b44cc70b34fa5edf0935890a1a09df12636794c83ac443602120bf3cecb466ea4437f781a271c664620824b15ae";
        let raw_cross_tx = x"f90265a0d696fd7dcc4af4ac5943143d59a415a8682fceb698a5a8e39f0bad0866847a1282013ef9023e9000000000000000000000000000000000a05991d3d0450c3c714c254ac7176184f5a95b417fa2bceff89f53bdcd3eece5d8b8c0000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000010f8ea2d94b8a7d83ace33bb56731268e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f7a696f6e5f6c6f636b5f70726f7879000000000000000000000000000000000082013eb8c0000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000010f8ea2d94b8a7d83ace33bb56731268e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f7a696f6e5f6c6f636b5f70726f7879000000000000000000000000000000000086756e6c6f636bb87c4a0000000000000000000000000000000105546f6b656e33546f6b656e3c307830303030303030303030303030303030303030303030303030303030303030313a3a5354433a3a5354433e1029ce635e538f628632963e92ed506d25204e000000000000000000000000000000000000000000000000000000000000";
        zion_lock_proxy::relay_unlock_tx<STC>(
            &sender,
            raw_header,
            raw_seals,
            account_proof,
            storage_proof,
            raw_cross_tx
        );
    }
}
// check: EXECUTED