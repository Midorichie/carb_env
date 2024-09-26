Here's the combined code with all the updates:
Python
import hashlib
import time
import ecdsa
import socket
import flask
import unittest
from typing import List, Dict
from enum import Enum
from dataclasses import dataclass

app = flask.Flask(__name__)

class CreditType(Enum):
    RENEWABLE_ENERGY = "Renewable Energy"
    REFORESTATION = "Reforestation"
    ENERGY_EFFICIENCY = "Energy Efficiency"

@dataclass
class CarbonCredit:
    credit_type: CreditType
    amount: float
    issuer: str
    issued_date: float
    expiry_date: float

class Transaction:
    def __init__(self, sender: str, recipient: str, credits: List[CarbonCredit], fee: float, private_key: ecdsa.SigningKey):
        self.sender = sender
        self.recipient = recipient
        self.credits = credits
        self.fee = fee
        self.timestamp = time.time()
        self.signature = self.sign_transaction(private_key)

    def sign_transaction(self, private_key: ecdsa.SigningKey) -> bytes:
        transaction_string = f"{self.sender}{self.recipient}{self.credits}{self.fee}{self.timestamp}"
        return private_key.sign(transaction_string.encode())

    def calculate_hash(self) -> str:
        transaction_string = f"{self.sender}{self.recipient}{self.credits}{self.fee}{self.timestamp}"
        return hashlib.sha256(transaction_string.encode()).hexdigest()

class Block:
    def __init__(self, index: int, transactions: List[Transaction], timestamp: float, previous_hash: str):
        self.index = index
        self.transactions = transactions
        self.timestamp = timestamp
        self.previous_hash = previous_hash
        self.nonce = 0
        self.hash = self.calculate_hash()

    def calculate_hash(self) -> str:
        block_string = f"{self.index}{[t.calculate_hash() for t in self.transactions]}{self.timestamp}{self.previous_hash}{self.nonce}"
        return hashlib.sha256(block_string.encode()).hexdigest()

    def mine_block(self, difficulty: int):
        target = "0" * difficulty
        while self.hash[:difficulty] != target:
            self.nonce += 1
            self.hash = self.calculate_hash()

class Blockchain:
    def __init__(self):
        self.chain: List[Block] = [self.create_genesis_block()]
        self.difficulty = 4
        self.pending_transactions: List[Transaction] = []
        self.mining_reward = 1
        self.credit_balances: Dict[str, Dict[CreditType, float]] = {}
        self.block_count = 0
        self.transaction_count = 0
        self.network_hash_rate = 0

    def create_genesis_block(self) -> Block:
        return Block(0, [], time.time(), "0")

    def get_latest_block(self) -> Block:
        return self.chain[-1]

    def mine_pending_transactions(self, miner_address: str):
        block = Block(len(self.chain), self.pending_transactions, time.time(), self.get_latest_block().hash)
        block.mine_block(self.difficulty)
        self.chain.append(block)
        self.pending_transactions = [
            Transaction("SYSTEM", miner_address, [CarbonCredit(CreditType.RENEWABLE_ENERGY, self.mining_reward, "SYSTEM", time.time(), time.time() + 31536000)], 0, ecdsa.SigningKey.generate())
        ]
        self._update_balances(block)
        self.block_count += 1
        self.transaction_count += len(block.transactions)

    def create_transaction(self, transaction: Transaction):
        try:
            if self._is_transaction_valid(transaction):
                self.pending_transactions.append(transaction)
                self.transaction_count += 1
            else:
                raise ValueError("Invalid transaction")
        except ValueError as e:
            print(f"Error creating transaction: {e}")

    def _is_transaction_valid(self, transaction: Transaction) -> bool:
        sender_balance = self.get_balance(transaction.sender)
        for credit in transaction.credits:
            if sender_balance.get(credit.credit_type, 0) < credit.amount:
                return False
        return True

    def get_balance(self, address: str) -> Dict[CreditType, float]:
        return self.credit_balances.get(address, {})

    def _update_balances(self, block: Block):
        for transaction in block.transactions:
            sender = transaction.sender
            recipient = transaction.recipient
            for credit in transaction.credits:
                # Deduct from sender
                if sender != "SYSTEM":
                    self.credit_balances.setdefault(sender, {})
                    self.credit_balances[sender][credit.credit_type] = self.credit_balances[sender].get(credit.credit_type, 0) - credit.amount
                
                # Add to recipient
                self.credit_balances.setdefault(recipient, {})
                self.credit_balances