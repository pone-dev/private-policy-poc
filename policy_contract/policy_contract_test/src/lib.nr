use aztec::test::helpers::test_environment::TestEnvironment;
use policy_contract_contract::Main;

#[test]
unconstrained fn test_constructor() {
    let mut env = TestEnvironment::new();
    let deployer = env.create_light_account();

    let _contract_address = env
        .deploy("@policy_contract_contract/Main")
        .with_private_initializer(
            deployer,
            Main::interface().constructor(),
        );
}

#[test]
unconstrained fn test_initialize_policy() {
    let mut env = TestEnvironment::new();
    let user = env.create_light_account();

    let contract_address = env
        .deploy("@policy_contract_contract/Main")
        .with_private_initializer(
            user,
            Main::interface().constructor(),
        );

    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );
}

#[test]
unconstrained fn test_spend_within_limit() {
    let mut env = TestEnvironment::new();
    let user = env.create_light_account();

    let contract_address = env
        .deploy("@policy_contract_contract/Main")
        .with_private_initializer(
            user,
            Main::interface().constructor(),
        );

    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );

    env.call_private(
        user,
        Main::at(contract_address).spend(3000),
    );
}

#[test(should_fail_with = "Daily spending limit exceeded")]
unconstrained fn test_spend_over_limit() {
    let mut env = TestEnvironment::new();
    let user = env.create_light_account();

    let contract_address = env
        .deploy("@policy_contract_contract/Main")
        .with_private_initializer(
            user,
            Main::interface().constructor(),
        );

    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );

    env.call_private(
        user,
        Main::at(contract_address).spend(6000),
    );
}

#[test]
unconstrained fn test_cumulative_spending_limit() {
    let mut env = TestEnvironment::new();
    let user = env.create_light_account();

    let contract_address = env
        .deploy("@policy_contract_contract/Main")
        .with_private_initializer(
            user,
            Main::interface().constructor(),
        );

    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );

    env.call_private(
        user,
        Main::at(contract_address).spend(3000),
    );

    env.call_private(
        user,
        Main::at(contract_address).spend(2000),
    );
}

#[test(should_fail_with = "Daily spending limit exceeded")]
unconstrained fn test_cumulative_spending_over_limit() {
    let mut env = TestEnvironment::new();
    let user = env.create_light_account();

    let contract_address = env
        .deploy("@policy_contract_contract/Main")
        .with_private_initializer(
            user,
            Main::interface().constructor(),
        );

    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );

    env.call_private(
        user,
        Main::at(contract_address).spend(3000),
    );

    env.call_private(
        user,
        Main::at(contract_address).spend(2000),
    );

    env.call_private(
        user,
        Main::at(contract_address).spend(1),
    );
}

#[test]
unconstrained fn test_multi_user_isolation() {
    let mut env = TestEnvironment::new();

    let user_a = env.create_light_account();
    let user_b = env.create_light_account();

    let contract_address = env
        .deploy("@policy_contract_contract/Main")
        .with_private_initializer(
            user_a,
            Main::interface().constructor(),
        );

    env.call_private(
        user_a,
        Main::at(contract_address).initialize_policy(5000),
    );

    env.call_private(
        user_b,
        Main::at(contract_address).initialize_policy(10000),
    );

    env.call_private(
        user_a,
        Main::at(contract_address).spend(5000),
    );

    env.call_private(
        user_b,
        Main::at(contract_address).spend(10000),
    );
}

#[test]
unconstrained fn test_update_policy() {
    let mut env = TestEnvironment::new();
    let user = env.create_light_account();

    let contract_address = env
        .deploy("@policy_contract_contract/Main")
        .with_private_initializer(
            user,
            Main::interface().constructor(),
        );

    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );

    env.call_private(
        user,
        Main::at(contract_address).update_policy(10000),
    );

    env.call_private(
        user,
        Main::at(contract_address).spend(8000),
    );
}

#[test(should_fail_with = "Daily spending limit exceeded")]
unconstrained fn test_updated_policy_enforces_new_limit() {
    let mut env = TestEnvironment::new();
    let user = env.create_light_account();

    let contract_address = env
        .deploy("@policy_contract_contract/Main")
        .with_private_initializer(
            user,
            Main::interface().constructor(),
        );

    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );

    env.call_private(
        user,
        Main::at(contract_address).update_policy(10000),
    );

    env.call_private(
        user,
        Main::at(contract_address).spend(10001),
    );
}

#[test]
unconstrained fn test_daily_reset_after_24_hours() {
    let mut env = TestEnvironment::new();
    let user = env.create_light_account();

    let contract_address = env
        .deploy("@policy_contract_contract/Main")
        .with_private_initializer(
            user,
            Main::interface().constructor(),
        );

    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );

    /*
     * Spend the entire daily limit.
     */
    env.call_private(
        user,
        Main::at(contract_address).spend(5000),
    );

    /*
     * Move forward by exactly 24 hours.
     */
    env.advance_next_block_timestamp_by(86400);
    env.mine_block();

    /*
     * The daily limit should now be available again.
     */
    env.call_private(
        user,
        Main::at(contract_address).spend(5000),
    );
}

#[test(should_fail_with = "Daily spending limit exceeded")]
unconstrained fn test_no_reset_before_24_hours() {
    let mut env = TestEnvironment::new();
    let user = env.create_light_account();

    let contract_address = env
        .deploy("@policy_contract_contract/Main")
        .with_private_initializer(
            user,
            Main::interface().constructor(),
        );

    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );

    /*
     * Spend 3000 during the current 24-hour period.
     */
    env.call_private(
        user,
        Main::at(contract_address).spend(3000),
    );

    /*
     * Move forward by less than 24 hours.
     */
    env.advance_next_block_timestamp_by(86399);
    env.mine_block();

    /*
     * 3000 + 2001 = 5001.
     *
     * The reset must NOT happen yet, so this call must fail.
     */
    env.call_private(
        user,
        Main::at(contract_address).spend(2001),
    );
}