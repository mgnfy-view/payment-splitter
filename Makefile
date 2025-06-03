-include .env

all : install fbuild

install :; forge soldeer install

update :; forge soldeer update

format :; forge fmt

compile :; forge compile

fbuild :; forge build

ftest :; forge test

snapshot :; forge snapshot

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

precommit :; forge fmt && git add .

deploy-payment-splitter :; forge script script/DeployPaymentSplitter.s.sol \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--verify \
	--etherscan-api-key $(ETHERSCAN_API_KEY) \
	--broadcast \
	-vvvv