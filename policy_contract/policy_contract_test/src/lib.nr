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

    let policy = Main::at(contract_address);

    env.call_private(
        user,
        policy.initialize_policy(5000),
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

    let policy = Main::at(contract_address);

    env.call_private(
        user,
        policy.initialize_policy(5000),
    );

    env.call_private(
        user,
        policy.spend(3000),
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

    let policy = Main::at(contract_address);

    env.call_private(
        user,
        policy.initialize_policy(5000),
    );

    env.call_private(
        user,
        policy.spend(6000),
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

    let policy = Main::at(contract_address);

    env.call_private(
        user,
        policy.initialize_policy(5000),
    );

    // First transaction: 3000 is allowed.
    env.call_private(
        user,
        policy.spend(3000),
    );

    // Second transaction: 2500 would make total spending 5500,
    // which exceeds the 5000 daily limit.
    env.call_private(
        user,
        policy.spend(2500),
    );
}