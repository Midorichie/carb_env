import hashlib
import time
from typing import List, Dict

class Block:
    def __init__(self, index: int, transactions: List[Dict], timestamp: float, previous_hash: str):
        self.index = index
        self.transactions = transactions
        self.timestamp = timestamp
        self.previous_hash = previous_hash
        self.nonce = 0
        self.hash = self.calculate_hash()

    def calculate_hash(self) -> str:
        block_string = f"{self.index}{self.transactions}{self.timestamp}{self.previous_hash}{self.nonce}"
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
        self.pending_transactions: List[Dict] = []
        self.mining_reward = 1

    def create_genesis_block(self) -> Block:
        return Block(0, [], time.time(), "0")

    def get_latest_block(self) -> Block:
        return self.chain[-1]

    def mine_pending_transactions(self, miner_address: str):
        block = Block(len(self.chain), self.pending_transactions, time.time(), self.get_latest_block().hash)
        block.mine_block(self.difficulty)
        self.chain.append(block)
        self.pending_transactions = [
            {"from": "SYSTEM", "to": miner_address, "amount": self.mining_reward}
        ]

    def create_transaction(self, sender: str, recipient: str, amount: float):
        self.pending_transactions.append({
            "from": sender,
            "to": recipient,
            "amount": amount
        })

    def get_balance(self, address: str) -> float:
        balance = 0
        for block in self.chain:
            for transaction in block.transactions:
                if transaction["from"] == address:
                    balance -= transaction["amount"]
                if transaction["to"] == address:
                    balance += transaction["amount"]
        return balance

    def is_chain_valid(self) -> bool:
        for i in range(1, len(self.chain)):
            current_block = self.chain[i]
            previous_block = self.chain[i-1]

            if current_block.hash != current_block.calculate_hash():
                return False

            if current_block.previous_hash != previous_block.hash:
                return False

        return True

# Example usage
blockchain = Blockchain()

blockchain.create_transaction("company1", "company2", 10)
blockchain.create_transaction("company2", "company1", 5)
blockchain.mine_pending_transactions("miner1")

blockchain.create_transaction("company1", "company3", 15)
blockchain.mine_pending_transactions("miner2")

print(f"Company1 balance: {blockchain.get_balance('company1')}")
print(f"Company2 balance: {blockchain.get_balance('company2')}")
print(f"Company3 balance: {blockchain.get_balance('company3')}")
print(f"Miner1 balance: {blockchain.get_balance('miner1')}")
print(f"Miner2 balance: {blockchain.get_balance('miner2')}")

print(f"Blockchain valid: {blockchain.is_chain_valid()}")