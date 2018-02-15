/*

  Copyright 2018 CoinAlpha, Inc.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.4.18;
import "./Basket.sol";

/**
  * @title BasketFactory -- Factory contract for creating different baskets
  * @author CoinAlpha, Inc. <contact@coinalpha.com>
  */
contract BasketFactory {

  // Basket register
  struct BasketStruct {
    address   basketAddress;
    string    name;
    string    symbol;
    address   arranger;
    address[] tokens;
    uint[]    weights;
  }

  // Baskets index starting from index = 1
  uint                          public basketIndex;
  mapping(uint => BasketStruct) public baskets;
  address[]                     public basketList;
  mapping(address => uint)      public basketIndexFromAddress;

  // Arrangers register
  uint                          public arrangerIndex;
  mapping(address => uint)      public arrangerBasketCount;
  address[]                     public arrangerList;
  mapping(address => uint)      public arrangerIndexFromAddress;

  // Modifiers
  modifier onlyBasket {
    require(basketIndexFromAddress[msg.sender] > 0);
    _;
  }

  // Events
  event LogBasketCreated(uint basketIndex, address basketAddress, address arranger);
  event LogBasketCloned(uint basketIndexOld, uint basketIndexClone, address newBasketAddress, address creator);

  // Constructor
  function BasketFactory () {
    basketIndex = 1;
  }

  // deploy a new basket
  function createBasket(
    string    _name,
    string    _symbol,
    address[] _tokens,
    uint[]    _weights
  )
    public
    returns (address newBasket)
  {
    Basket b = new Basket(_name, _symbol, _tokens, _weights);
    baskets[basketIndex] = BasketStruct(b, _name, _symbol, msg.sender, _tokens, _weights);
    basketList.push(b);
    basketIndexFromAddress[b] = basketIndex;

    if (arrangerBasketCount[msg.sender] == 0) {
      arrangerList.push(msg.sender);
      arrangerIndexFromAddress[msg.sender] = arrangerIndex;
      arrangerIndex += 1;
    }
    arrangerBasketCount[msg.sender] += 1;

    LogBasketCreated(basketIndex, b, msg.sender);
    basketIndex += 1;
    return b;
  }

  // Copy an existing basket
  function copyBasket(uint _sourceBasketIndex)
    public
    returns (address newBasket)
  {
    BasketStruct source = baskets[_sourceBasketIndex];
    Basket b = new Basket(source.name, source.symbol, source.tokens, source.weights);
    baskets[basketIndex] = BasketStruct(b, source.name, source.symbol, source.arranger, source.tokens, source.weights);
    basketList.push(b);
    basketIndexFromAddress[b] = basketIndex;
    arrangerBasketCount[source.arranger] += 1;
    LogBasketCloned(_sourceBasketIndex, basketIndex, b, msg.sender);
    basketIndex += 1;
    return b;
  }

  // Clone an existing basket called from source basket contract
  function cloneBasket()
    public
    onlyBasket
    returns (address newBasket)
  {
    uint sourceBasketIndex = basketIndexFromAddress[msg.sender];
    return copyBasket(sourceBasketIndex);
  }

}