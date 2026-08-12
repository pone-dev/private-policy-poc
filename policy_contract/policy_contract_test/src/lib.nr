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

    // First spend: 3000.
    env.call_private(
        user,
        Main::at(contract_address).spend(3000),
    );

    // Second spend: 1500.
    // Cumulative total = 4500, which is below the 5000 limit.
    env.call_private(
        user,
        Main::at(contract_address).spend(1500),
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

    // First spend: 3000.
    env.call_private(
        user,
        Main::at(contract_address).spend(3000),
    );

    // Second spend would make the cumulative total 5001.
    env.call_private(
        user,
        Main::at(contract_address).spend(2001),
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

    // Initial limit = 5000.
    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );

    // Update limit = 10000.
    env.call_private(
        user,
        Main::at(contract_address).update_policy(10000),
    );

    // 8000 is now allowed.
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

    // Initial limit = 5000.
    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );

    // Increase limit to 10000.
    env.call_private(
        user,
        Main::at(contract_address).update_policy(10000),
    );

    // 10001 exceeds the new limit.
    env.call_private(
        user,
        Main::at(contract_address).spend(10001),
    );
}