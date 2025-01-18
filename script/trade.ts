import { ethers } from 'ethers';
import * as dotenv from 'dotenv';

dotenv.config();

const FLIP_CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS!;
const RPC_URL = process.env.RPC_URL!;
const PRIVATE_KEY = process.env.PRIVATE_KEY!;

const ABI = [
    "function mint() public payable",
    "function quickBuy() public payable",
    "function sell(uint256 tokenId) public",
    "function getBuyPriceAfterFee() public view returns (uint256)",
    "function getSellPriceAfterFee() public view returns (uint256)",
    "function balanceOf(address owner) public view returns (uint256)",
    "function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256)"
];

class TradeManager {
    private provider: ethers.JsonRpcProvider;
    private signer: ethers.Wallet;
    private contractAddress: string;

    constructor(rpcUrl: string, privateKey: string, contractAddress: string) {
        this.provider = new ethers.JsonRpcProvider(rpcUrl);
        this.signer = new ethers.Wallet(privateKey, this.provider);
        this.contractAddress = contractAddress;
    }

    async executeTrade() {
        console.log('executeTrade with wallet', this.signer.address);
        const contract = new ethers.Contract(this.contractAddress, ABI, this.signer);

        try {
            const balance = await this.provider.getBalance(this.signer.address);
            console.log(`Current wallet: ${this.signer.address}, Balance: ${ethers.formatEther(balance)} ETH`);

            if (balance === BigInt(0)) {
                console.log('Skipping wallet with zero balance');
                return;
            }

            const operation = Math.floor(Math.random() * 3);
            
            switch (operation) {
                case 0: // Mint
                    const mintPrice = await contract.getBuyPriceAfterFee();
                    console.log(`Mint price: ${ethers.formatEther(mintPrice)} ETH`);
                    if (balance > mintPrice) {
                        const tx = await contract.mint({ value: mintPrice });
                        await tx.wait();
                        console.log(`Minted new token from wallet ${this.signer.address}, tx: ${tx.hash} ${tx.status}`);
                    }
                    break;

                case 1: // Quick Buy
                    const buyPrice = await contract.getBuyPriceAfterFee();
                    console.log(`Buy price: ${ethers.formatEther(buyPrice)} ETH`);
                    if (balance > buyPrice) {
                        const tx = await contract.quickBuy({ value: buyPrice });
                        await tx.wait();
                        console.log(`Bought token via quickBuy from wallet ${this.signer.address}, tx: ${tx.hash}`);
                    }
                    break;

                case 2: // Sell
                    const nftBalance = await contract.balanceOf(this.signer.address);
                    if (nftBalance > 0) {
                        const tokenId = await contract.tokenOfOwnerByIndex(this.signer.address, 0);
                        const tx = await contract.sell(tokenId);
                        await tx.wait();
                        console.log(`Sold token ${tokenId} from wallet ${this.signer.address}, tx: ${tx.hash}`);
                    }
                    break;
            }
        } catch (error) {
            console.error(`Error executing trade for wallet ${this.signer.address}:`, error);
        }
    }

    async startTrading(intervalSeconds: number) {
        
        await this.executeTrade();
        
        const scheduleNextTrade = () => {
            const randomDelay = Math.floor(Math.random() * intervalSeconds * 1000);
            setTimeout(() => {
                this.executeTrade().then(() => scheduleNextTrade());
            }, randomDelay);
        };
        
        scheduleNextTrade();
    }
}

async function main() {
    const tradeManager = new TradeManager(RPC_URL, PRIVATE_KEY, FLIP_CONTRACT_ADDRESS);
    
    await tradeManager.startTrading(1);
}

main().catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
});