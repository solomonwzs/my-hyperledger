#!/usr/bin/python3
# encoding: utf8

import hashlib
import json
import logging
import requests
from textwrap import dedent
from time import time
from urllib.parse import urlparse
from uuid import uuid4

from flask import Flask, jsonify, request


class Blockchain(object):
    def __init__(self):
        self.chain = []
        self.__current_transactions = []
        self.nodes = set()
        self.new_block(previous_hash='1', proof=100)

    def new_block(self, proof: int, previous_hash: str=None):
        block = {
            "index": len(self.chain) + 1,
            "timestamp": time(),
            "transactions": self.__current_transactions,
            "proof": proof,
            "previous_hash": previous_hash or self.hash(self.chain[-1]),
        }
        self.__current_transactions = []
        self.chain.append(block)
        return block

    def proof_of_work(self, last_proof: int):
        proof = 0
        while self.valid_proof(last_proof, proof) is False:
            proof += 1
        return proof

    @staticmethod
    def valid_proof(last_proof, proof):
        guess = f"{last_proof}{proof}".encode()
        guess_hash = hashlib.sha256(guess).hexdigest()
        return guess_hash[:4] == "0000"

    def new_transactions(self, sender: str, recipient: str, amount: int):
        self.__current_transactions.append({
            "sender": sender,
            "recipient": recipient,
            "amount": amount,
        })
        return self.last_block["index"] + 1

    @staticmethod
    def hash(block):
        block_string = json.dumps(block, sort_keys=True).encode()
        return hashlib.sha256(block_string).hexdigest()

    @property
    def last_block(self):
        return self.chain[-1]

    def register_node(self, address):
        parsed_url = urlparse(address)
        self.nodes.add(parsed_url.netloc)

    def valid_chain(self, chain):
        prev_block = chain[0]
        current_index = 1
        while current_index < len(chain):
            block = chain[current_index]
            logging.DEBUG(f"{last_block}")
            logging.DEBUG(f"{block}")
            logging.DEBUG("\n--------\n")

            if block["previous_hash"] != self.hash(prev_block):
                return False

            prev_block = block
            current_index += 1
        return True

    def resolve_conflicts(self):
        new_chain = None
        max_length = len(self.chain)

        for node in self.nodes:
            response = requests.get(f'http://{node}/chain')
            if response.status_code == 200:
                values = response.json()
                length = values["length"]
                chain = values["chain"]

                if length > max_length and self.valid_chain(chain):
                    max_length = length
                    new_chain = chain

        if new_chain is not None:
            self.chain = new_chain
            return True
        return False


app = Flask(__name__)

node_identifier = str(uuid4()).replace('-', '')

blockchain = Blockchain()


@app.route("/mine", methods=["GET"])
def mine():
    last_block = blockchain.last_block
    last_proof = last_block["proof"]
    proof = blockchain.proof_of_work(last_proof)

    blockchain.new_transactions(sender="0", recipient=node_identifier,
                                amount=1)
    block = blockchain.new_block(proof)

    response = {
        "message": "New Block Forged",
        "index": block["index"],
        "transactions": block["transactions"],
        "proof": block["proof"],
        "previous_hash": block["previous_hash"],
    }
    return jsonify(response), 200


@app.route("/transactions/new", methods=["POST"])
def new_transaction():
    values = request.get_json()

    required = ["sender", "recipient", "amount"]
    if not all(k in values for k in required):
        return "Missing value", 400

    index = blockchain.new_transactions(values["sender"], values["recipient"],
                                        values["amount"])

    response = {"message": f"Transaction will be added to Block {index}"}
    return jsonify(response), 201


@app.route("/chain", methods=["GET"])
def full_chain():
    response = {
        "chain": blockchain.chain,
        "length": len(blockchain.chain),
    }
    return jsonify(response), 200


@app.route("/nodes/register", methods=["POST"])
def register_nodes():
    values = request.get_json()
    nodes = values.get("nodes")
    if nodes is None:
        return "Error: Please supply a valid list of nodes", 400

    for node in nodes:
        blockchain.register_node(node)

    return {
        "message": "New nodes have been adder",
        "total_nodes": list(blockchain.nodes),
    }, 201


@app.route("/nodes/resolve", methods=["GET"])
def consensus():
    replace = blockchain.resolve_conflicts()

    if replace:
        response = {
            "message": "Our chain was replace",
            "new_chain": blockchain.chain,
        }
    else:
        response = {
            "message": "Our chain was authoritative",
            "new_chain": blockchain.chain,
        }
    return jsonify(response), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
