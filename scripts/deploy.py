from brownie import FundMe, network, config, MockV3Aggregator
from scripts.helpul_scripts import get_account, deploy_mock, LOCAL_BLOCKCHAIN_ENVIRONMENTS

def deploy_fund_me():
    account = get_account()

    # if we are con a persistent network like rinkeby, use the associated address
    # otherwise, deploy mocks
    # entonces desarrollamos este if:
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    else:
        deploy_mock()
        price_feed_address = MockV3Aggregator[-1].address
        

    fund_me = FundMe.deploy(  # se pone la wallet antes del from porque de esta manera le pasamos variables al constructor cuando compila
        price_feed_address,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify"),
    )
    print(f"Contract deployed to {fund_me.address}")
    return fund_me


def main():
    deploy_fund_me()
