use aztec::macros::aztec;

#[aztec]
pub contract Main {
    use aztec::{
        macros::{
            functions::{external, initializer},
            storage::storage,
        },
        messages::delivery::MessageDelivery,
        protocol::address::AztecAddress,
        state_vars::{Owned, PrivateMutable},
    };

    use uint_note::UintNote;

    #[storage]
    struct Storage<Context> {
        daily_limit: Owned<PrivateMutable<UintNote, Context>, Context>,
        spent_today: Owned<PrivateMutable<UintNote, Context>, Context>,
        last_reset_timestamp: Owned<PrivateMutable<UintNote, Context>, Context>,
    }

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    #[initializer]
    #[external("private")]
    fn constructor() {}

    // ============================================================
    // INITIALIZE POLICY
    // ============================================================

    #[external("private")]
    fn initialize_policy(daily_limit: u128) {
        let owner = self.msg_sender();

        // Store the daily spending limit.
        self.storage
            .daily_limit
            .at(owner)
            .initialize(UintNote {
                value: daily_limit,
            })
            .deliver(MessageDelivery::onchain_constrained());

        // Start cumulative spending at zero.
        self.storage
            .spent_today
            .at(owner)
            .initialize(UintNote {
                value: 0,
            })
            .deliver(MessageDelivery::onchain_constrained());

        // Store the beginning of the current 24-hour period.
        let current_timestamp =
            self.context.get_anchor_block_header().timestamp();

        self.storage
            .last_reset_timestamp
            .at(owner)
            .initialize(UintNote {
                value: current_timestamp as u128,
            })
            .deliver(MessageDelivery::onchain_constrained());
    }

    // ============================================================
    // UPDATE POLICY
    // ============================================================

    #[external("private")]
    fn update_policy(new_daily_limit: u128) {
        let owner = self.msg_sender();

        self.storage
            .daily_limit
            .at(owner)
            .replace(|_old_limit| {
                UintNote {
                    value: new_daily_limit,
                }
            })
            .deliver(MessageDelivery::onchain_constrained());
    }

    // ============================================================
    // SPEND
    // ============================================================

    #[external("private")]
    fn spend(amount: u128) {
        let owner = self.msg_sender();

        // Current block timestamp.
        let current_timestamp =
            self.context.get_anchor_block_header().timestamp();

        // --------------------------------------------------------
        // Read daily limit.
        //
        // get_note() consumes the current note and recreates it.
        // Therefore the returned NoteMessage must be delivered.
        // --------------------------------------------------------

        let limit_message = self
            .storage
            .daily_limit
            .at(owner)
            .get_note();

        let limit_value = limit_message.get_note().value;

        limit_message
            .deliver(MessageDelivery::onchain_constrained());

        // --------------------------------------------------------
        // Read last reset timestamp.
        // --------------------------------------------------------

        let reset_message = self
            .storage
            .last_reset_timestamp
            .at(owner)
            .get_note();

        let last_reset_timestamp =
            reset_message.get_note().value as u64;

        reset_message
            .deliver(MessageDelivery::onchain_constrained());

        // --------------------------------------------------------
        // Check whether 24 hours have passed.
        //
        // 24 hours = 86400 seconds.
        // --------------------------------------------------------

        let reset_required =
            current_timestamp >= last_reset_timestamp + 86400;

        if reset_required {
            // ----------------------------------------------------
            // New 24-hour period.
            // ----------------------------------------------------

            self.storage
                .last_reset_timestamp
                .at(owner)
                .replace(|_old_timestamp| {
                    UintNote {
                        value: current_timestamp as u128,
                    }
                })
                .deliver(MessageDelivery::onchain_constrained());

            // This is the first spend of the new period.
            self.storage
                .spent_today
                .at(owner)
                .replace(|_old_spent| {
                    assert(
                        amount <= limit_value,
                        "Daily spending limit exceeded",
                    );

                    UintNote {
                        value: amount,
                    }
                })
                .deliver(MessageDelivery::onchain_constrained());
        } else {
            // ----------------------------------------------------
            // Existing 24-hour period.
            // ----------------------------------------------------

            self.storage
                .spent_today
                .at(owner)
                .replace(|old_spent| {
                    let new_spent = old_spent.value + amount;

                    assert(
                        new_spent <= limit_value,
                        "Daily spending limit exceeded",
                    );

                    UintNote {
                        value: new_spent,
                    }
                })
                .deliver(MessageDelivery::onchain_constrained());
        }
    }

    // ============================================================
    // UTILITY: GET DAILY LIMIT
    // ============================================================
    //
    // Utility functions execute off-chain in UtilityContext.
    //
    // view_note() reads the private note without consuming it.
    //
    // `pub` on the return type is required for an external utility
    // function because the value is returned to the caller.
    // ============================================================

    #[external("utility")]
    unconstrained fn get_daily_limit(
        owner: AztecAddress,
    ) -> pub u128 {
        self.storage
            .daily_limit
            .at(owner)
            .view_note()
            .value
    }

    // ============================================================
    // UTILITY: GET SPENT TODAY
    // ============================================================

    #[external("utility")]
    unconstrained fn get_spent_today(
        owner: AztecAddress,
    ) -> pub u128 {
        self.storage
            .spent_today
            .at(owner)
            .view_note()
            .value
    }

    // ============================================================
    // UTILITY: GET LAST RESET TIMESTAMP
    // ============================================================

    #[external("utility")]
    unconstrained fn get_last_reset_timestamp(
        owner: AztecAddress,
    ) -> pub u64 {
        self.storage
            .last_reset_timestamp
            .at(owner)
            .view_note()
            .value as u64
    }

    // ============================================================
    // UTILITY: GET COMPLETE POLICY STATUS
    // ============================================================
    //
    // Returns:
    //
    // 1. Daily spending limit
    // 2. Amount spent during current 24-hour period
    // 3. Timestamp of the current period's reset
    //
    // This will be the main function we can use from the frontend.
    // ============================================================

    #[external("utility")]
    unconstrained fn get_policy_status(
        owner: AztecAddress,
    ) -> pub (u128, u128, u64) {
        let daily_limit = self
            .storage
            .daily_limit
            .at(owner)
            .view_note()
            .value;

        let spent_today = self
            .storage
            .spent_today
            .at(owner)
            .view_note()
            .value;

        let last_reset_timestamp = self
            .storage
            .last_reset_timestamp
            .at(owner)
            .view_note()
            .value as u64;

        (
            daily_limit,
            spent_today,
            last_reset_timestamp,
        )
    }
}