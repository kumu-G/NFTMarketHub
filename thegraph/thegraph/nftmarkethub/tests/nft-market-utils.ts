import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  Deal,
  EIP712DomainChanged,
  NewOrder,
  OrderCancelled,
  PriceChanged
} from "../generated/NFTMarket/NFTMarket"

export function createDealEvent(
  seller: Address,
  buyer: Address,
  tokenId: BigInt,
  price: BigInt
): Deal {
  let dealEvent = changetype<Deal>(newMockEvent())

  dealEvent.parameters = new Array()

  dealEvent.parameters.push(
    new ethereum.EventParam("seller", ethereum.Value.fromAddress(seller))
  )
  dealEvent.parameters.push(
    new ethereum.EventParam("buyer", ethereum.Value.fromAddress(buyer))
  )
  dealEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  dealEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )

  return dealEvent
}

export function createEIP712DomainChangedEvent(): EIP712DomainChanged {
  let eip712DomainChangedEvent = changetype<EIP712DomainChanged>(newMockEvent())

  eip712DomainChangedEvent.parameters = new Array()

  return eip712DomainChangedEvent
}

export function createNewOrderEvent(
  seller: Address,
  tokenId: BigInt,
  price: BigInt
): NewOrder {
  let newOrderEvent = changetype<NewOrder>(newMockEvent())

  newOrderEvent.parameters = new Array()

  newOrderEvent.parameters.push(
    new ethereum.EventParam("seller", ethereum.Value.fromAddress(seller))
  )
  newOrderEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  newOrderEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )

  return newOrderEvent
}

export function createOrderCancelledEvent(
  seller: Address,
  tokenId: BigInt
): OrderCancelled {
  let orderCancelledEvent = changetype<OrderCancelled>(newMockEvent())

  orderCancelledEvent.parameters = new Array()

  orderCancelledEvent.parameters.push(
    new ethereum.EventParam("seller", ethereum.Value.fromAddress(seller))
  )
  orderCancelledEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )

  return orderCancelledEvent
}

export function createPriceChangedEvent(
  seller: Address,
  tokenId: BigInt,
  previousPrice: BigInt,
  price: BigInt
): PriceChanged {
  let priceChangedEvent = changetype<PriceChanged>(newMockEvent())

  priceChangedEvent.parameters = new Array()

  priceChangedEvent.parameters.push(
    new ethereum.EventParam("seller", ethereum.Value.fromAddress(seller))
  )
  priceChangedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  priceChangedEvent.parameters.push(
    new ethereum.EventParam(
      "previousPrice",
      ethereum.Value.fromUnsignedBigInt(previousPrice)
    )
  )
  priceChangedEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )

  return priceChangedEvent
}
