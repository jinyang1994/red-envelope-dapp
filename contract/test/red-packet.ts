import { expect } from 'chai'
import { ethers } from 'hardhat'

describe('RedPacket', function () {
  it('User create a red packet(ETH) and get it', async function () {
    const [signer] = await ethers.getSigners()
    const data = {
      token: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
      amount: '100000000',
      quantity: 1,
      message: 'Hello World',
      allowed: []
    }
    const Contract = await ethers.getContractFactory('RedPacket')
    const contract = await Contract.deploy()

    // deployed
    await contract.deployed()

    // create packet
    const tx = await contract.createPacket(
      data.token,
      data.amount,
      data.quantity,
      data.message,
      data.allowed,
      {
        value: ethers.BigNumber.from(data.amount).toHexString()
      }
    )
    
    const receipt = await tx.wait()
    // get red packet
    const event = receipt.events?.find(item => item.event === 'CreatePacket')
    const id = event?.args?.id.toString()
    const packet = await contract.getPacket(id)

    // check red packet data
    expect(packet.token).to.be.equal(data.token)
    expect(packet.sender).to.be.equal(signer.address)
    expect(packet.total.toString()).to.be.equal(data.amount)
    expect(packet.quantity.toNumber()).to.be.equal(data.quantity)
    expect(packet.message).to.be.equal(data.message)
    expect(packet.allowedCount).to.be.deep.equal(data.allowed.length)
  })

  it('Use isAllowed check user access', async function () {
    const [signer, other] = await ethers.getSigners()
    const data = {
      token: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
      amount: '100000000',
      quantity: 1,
      message: 'Hello World',
      allowed: [signer.address]
    }
    const Contract = await ethers.getContractFactory('RedPacket')
    const contract = await Contract.deploy()

    // deployed
    await contract.deployed()

    // create packet specify allowed
    await contract.createPacket(
      data.token,
      data.amount,
      data.quantity,
      data.message,
      data.allowed,
      {
        value: ethers.BigNumber.from(data.amount).toHexString()
      }
    )

    // create packet not specify allowed
    await contract.createPacket(
      data.token,
      data.amount,
      data.quantity,
      data.message,
      [],
      {
        value: ethers.BigNumber.from(data.amount).toHexString()
      }
    )

    // check
    {
      const isAllowed = await contract.isAllowed(1, signer.address)
      expect(isAllowed).to.be.true
    }
    {
      const isAllowed = await contract.isAllowed(1, other.address)
      expect(isAllowed).to.be.false
    }
    {
      const isAllowed = await contract.isAllowed(2, other.address)
      expect(isAllowed).to.be.true
    }
  })
})
