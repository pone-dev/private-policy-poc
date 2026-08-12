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

#[test(should_fail_with = "Daily spending limit exceeded")]
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

    // Initial limit: 5000.
    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );

    // Update limit: 10000.
    env.call_private(
        user,
        Main::at(contract_address).update_policy(10000),
    );

    // Should now be allowed because the new limit is 10000.
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

    // Initial limit: 5000.
    env.call_private(
        user,
        Main::at(contract_address).initialize_policy(5000),
    );

    // Increase it to 10000.
    env.call_private(
        user,
        Main::at(contract_address).update_policy(10000),
    );

    // 10000 is the maximum, so 10001 must fail.
    env.call_private(
        user,
        Main::at(contract_address).spend(10001),
    );
}