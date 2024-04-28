// Copyright (c) RoochNetwork
// SPDX-License-Identifier: Apache-2.0

use crate::address::{MultiChainAddress, RoochAddress};
use crate::addresses::ROOCH_FRAMEWORK_ADDRESS;
use anyhow::{Ok, Result};
use move_core_types::{account_address::AccountAddress, ident_str, identifier::IdentStr};
use moveos_types::moveos_std::object;
use moveos_types::moveos_std::object::ObjectID;
use moveos_types::state::MoveStructType;
use moveos_types::{
    module_binding::{ModuleBinding, MoveFunctionCaller},
    move_std::option::MoveOption,
    moveos_std::tx_context::TxContext,
    state::MoveState,
    transaction::FunctionCall,
};
use serde::{Deserialize, Serialize};

pub const MODULE_NAME: &IdentStr = ident_str!("address_mapping");

pub const NAMED_MAPPING_INDEX: u64 = 0;
pub const NAMED_REVERSE_MAPPING_INDEX: u64 = 1;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AddressMappingWrapper {
    // mapping: Table<MultiChainAddress, AccountAddress>,
    // mapping: Table<MultiChainAddress, RoochAddress>,
    // reverse_mapping: Table<AccountAddress, Vec<MultiChainAddress>>,
    // reverse_mapping: Table<RoochAddress, Vec<MultiChainAddress>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AddressMappingIndex {
    pub index: u64,
}

impl MoveStructType for AddressMappingWrapper {
    const ADDRESS: AccountAddress = ROOCH_FRAMEWORK_ADDRESS;
    const MODULE_NAME: &'static IdentStr = MODULE_NAME;
    const STRUCT_NAME: &'static IdentStr = ident_str!("AddressMapping");
}

impl AddressMappingWrapper {
    pub fn address_mapping_object_id() -> ObjectID {
        object::named_object_id(&Self::struct_tag())
    }

    pub fn mapping_object_id() -> ObjectID {
        let named_index = AddressMappingIndex {
            index: NAMED_MAPPING_INDEX,
        };
        object::custom_object_id(&named_index, &Self::struct_tag())
    }

    pub fn reverse_mapping_object_id() -> ObjectID {
        let named_index = AddressMappingIndex {
            index: NAMED_REVERSE_MAPPING_INDEX,
        };
        object::custom_object_id(&named_index, &Self::struct_tag())
    }
}

// #[derive(Debug, Clone, Serialize, Deserialize)]
// pub struct AddressMapping {
//     mapping: Table<MultiChainAddress, AccountAddress>,
//     // mapping: Table<MultiChainAddress, RoochAddress>,
//     reverse_mapping: Table<AccountAddress, Vec<MultiChainAddress>>,
//     // reverse_mapping: Table<RoochAddress, Vec<MultiChainAddress>>,
// }
//
// impl MoveStructType for AddressMapping {
//     const ADDRESS: AccountAddress = ROOCH_FRAMEWORK_ADDRESS;
//     const MODULE_NAME: &'static IdentStr = MODULE_NAME;
//     const STRUCT_NAME: &'static IdentStr = ident_str!("AddressMapping");
// }
//
// impl MoveStructState for AddressMapping {
//     fn struct_layout() -> MoveStructLayout {
//         MoveStructLayout::new(vec![
//             MoveTypeLayout::Struct(Table::<MultiChainAddress, AccountAddress>::struct_layout()),
//             MoveTypeLayout::Struct(
//                 Table::<AccountAddress, Vec<MultiChainAddress>>::struct_layout(),
//             ),
//         ])
//     }
// }
//
// impl AddressMapping {
//     pub fn address_mapping_object_id() -> ObjectID {
//         object::named_object_id(&Self::struct_tag())
//     }
// }

/// Rust bindings for RoochFramework address_mapping module
pub struct AddressMappingModule<'a> {
    caller: &'a dyn MoveFunctionCaller,
}

impl<'a> AddressMappingModule<'a> {
    const RESOLVE_FUNCTION_NAME: &'static IdentStr = ident_str!("resolve");
    const RESOLVE_OR_GENERATE_FUNCTION_NAME: &'static IdentStr = ident_str!("resolve_or_generate");
    const ADDRESS_MAPPING_HANDLE_FUNCTION_NAME: &'static IdentStr =
        ident_str!("address_mapping_handle");

    pub fn resolve(&self, multichain_address: MultiChainAddress) -> Result<Option<AccountAddress>> {
        if multichain_address.is_rooch_address() {
            let rooch_address: RoochAddress = multichain_address.try_into()?;
            Ok(Some(rooch_address.into()))
        } else {
            let ctx = TxContext::zero();
            let call = FunctionCall::new(
                Self::function_id(Self::RESOLVE_FUNCTION_NAME),
                vec![],
                vec![multichain_address.to_bytes()],
            );
            let result = self
                .caller
                .call_function(&ctx, call)?
                .into_result()
                .map(|values| {
                    let value = values.first().expect("Expected return value");
                    let result = MoveOption::<AccountAddress>::from_bytes(&value.value)
                        .expect("Expected Option<address>");
                    result.into()
                })?;
            Ok(result)
        }
    }

    pub fn resolve_or_generate(
        &self,
        multichain_address: MultiChainAddress,
    ) -> Result<AccountAddress> {
        if multichain_address.is_rooch_address() {
            let rooch_address: RoochAddress = multichain_address.try_into()?;
            Ok(rooch_address.into())
        } else {
            let ctx = TxContext::zero();
            let call = FunctionCall::new(
                Self::function_id(Self::RESOLVE_OR_GENERATE_FUNCTION_NAME),
                vec![],
                vec![multichain_address.to_bytes()],
            );
            let address = self
                .caller
                .call_function(&ctx, call)?
                .into_result()
                .map(|values| {
                    let value = values.first().expect("Expected return value");
                    AccountAddress::from_bytes(&value.value).expect("Expected return address")
                })?;
            Ok(address)
        }
    }

    pub fn address_mapping_handle(&self) -> Result<(ObjectID, ObjectID, ObjectID)> {
        let ctx = TxContext::zero();
        let call = FunctionCall::new(
            Self::function_id(Self::ADDRESS_MAPPING_HANDLE_FUNCTION_NAME),
            vec![],
            vec![],
        );

        let (address_mapping_handle, mapping_handle, reverse_mapping_handle) = self
            .caller
            .call_function(&ctx, call)?
            .into_result()
            .map(|values| {
                let value0 = values.first().ok_or(anyhow::anyhow!(
                    "Address mapping handle expected return value"
                ))?;
                let value1 = values.get(1).ok_or(anyhow::anyhow!(
                    "Address mapping handle expected return value"
                ))?;
                let value2 = values.get(2).ok_or(anyhow::anyhow!(
                    "Address mapping handle expected return value"
                ))?;
                let address_mapping_handle =
                    ObjectID::from_bytes(value0.value.clone()).map_err(|e| {
                        anyhow::anyhow!("Address mapping handle convert error {}", e.to_string())
                    })?;
                let mapping_handle = ObjectID::from_bytes(value1.value.clone()).map_err(|e| {
                    anyhow::anyhow!("Address mapping handle convert error {}", e.to_string())
                })?;
                let reverse_mapping_handle =
                    ObjectID::from_bytes(value2.value.clone()).map_err(|e| {
                        anyhow::anyhow!("Address mapping handle convert error {}", e.to_string())
                    })?;
                Ok((
                    address_mapping_handle,
                    mapping_handle,
                    reverse_mapping_handle,
                ))
            })??;

        Ok((
            address_mapping_handle,
            mapping_handle,
            reverse_mapping_handle,
        ))
    }
}

impl<'a> ModuleBinding<'a> for AddressMappingModule<'a> {
    const MODULE_NAME: &'static IdentStr = ident_str!("address_mapping");
    const MODULE_ADDRESS: AccountAddress = ROOCH_FRAMEWORK_ADDRESS;

    fn new(caller: &'a impl MoveFunctionCaller) -> Self
    where
        Self: Sized,
    {
        Self { caller }
    }
}
