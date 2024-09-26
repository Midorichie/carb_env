import hashlib
import time
from typing import List, Dict
from enum import Enum
from dataclasses import dataclass

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
    def __init__(self, sender: str, recipient: str, credits: List[CarbonCredit]):
        self.sender = sender
        self.recipient = recipient
        self.credits = credits
        self.timestamp = time.time()

    def calculate_hash(self) -> str:
        transaction_string = f"{self.sender}{self.recipient}{self.credits}{self.timestamp}"
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

    def create_genesis_block(self) -> Block:
        return Block(0, [], time.time(), "0")

    def get_latest_block(self) -> Block:
        return self.chain[-1]

    def mine_pending_transactions(self, miner_address: str):
        block = Block(len(self.chain), self.pending_transactions, time.time(), self.get_latest_block().hash)
        block.mine_block(self.difficulty)
        self.chain.append(block)
        self.pending_transactions = [
            Transaction("SYSTEM", miner_address, [CarbonCredit(CreditType.RENEWABLE_ENERGY, self.mining_reward, "SYSTEM", time.time(), time.time() + 31536000)])
        ]
        self._update_balances(block)

    def create_transaction(self, transaction: Transaction):
        if self._is_transaction_valid(transaction):
            self.pending_transactions.append(transaction)
        else:
            raise ValueError("Invalid transaction")

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
                self.credit_balances[recipient][credit.credit_type] = self.credit_balances[recipient].get(credit.credit_type, 0) + credit.amount

    def is_chain_valid(self) -> bool:
        for i in range(1, len(self.chain)):
            current_block = self.chain[i]
            previous_block = self.chain[i-1]

            if current_block.hash != current_block.calculate_hash():
                return False

            if current_block.previous_hash != previous_block.hash:
                return False

        return True

    def get_all_transactions(self, address: str) -> List[Transaction]:
        transactions = []
        for block in self.chain:
            for transaction in block.transactions:
                if transaction.sender == address or transaction.recipient == address:
                    transactions.append(transaction)
        return transactions

# Example usage
blockchain = Blockchain()

# Create some initial carbon credits
blockchain.create_transaction(Transaction("SYSTEM", "company1", [CarbonCredit(CreditType.RENEWABLE_ENERGY, 100, "SYSTEM", time.time(), time.time() + 31536000)]))
blockchain.create_transaction(Transaction("SYSTEM", "company2", [CarbonCredit(CreditType.REFORESTATION, 50, "SYSTEM", time.time(), time.time() + 31536000)]))
blockchain.mine_pending_transactions("miner1")

# Perform a transaction
blockchain.create_transaction(Transaction("company1", "company3", [CarbonCredit(CreditType.RENEWABLE_ENERGY, 30, "SYSTEM", time.time(), time.time() + 31536000)]))
blockchain.mine_pending_transactions("miner2")

print("Company1 balance:", blockchain.get_balance("company1"))
print("Company2 balance:", blockchain.get_balance("company2"))
print("Company3 balance:", blockchain.get_balance("company3"))
print("Miner1 balance:", blockchain.get_balance("miner1"))
print("Miner2 balance:", blockchain.get_balance("miner2"))

print("Blockchain valid:", blockchain.is_chain_valid())

print("Company1 transactions:", blockchain.get_all_transactions("company1"))