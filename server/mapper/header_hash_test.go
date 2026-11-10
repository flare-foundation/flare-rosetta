package mapper

import (
	"encoding/json"
	"testing"

	"github.com/ava-labs/avalanchego/graft/coreth/plugin/evm"
	"github.com/ava-labs/libevm/common"
	"github.com/ava-labs/libevm/core/types"
	"github.com/stretchr/testify/require"
)

// heliconHeaderJSON is an SAE (post-Helicon) C-chain header returned by a
// go-flare v1.15.1 localflare node. It carries Flare's pChainHeight header
// field, which upstream coreth does not know about: decoding it with upstream
// customtypes yields a different block hash, so every follow-up lookup by hash
// (eth_getBlockByHash, debug_traceBlockByHash, ...) fails with
// "block not found". This is why go.mod replaces avalanchego with go-flare.
const heliconHeaderJSON = `{"baseFeePerGas":"0x1","blobGasUsed":"0x0","blockGasCost":"0x0","difficulty":"0x1","excessBlobGas":"0x0","extDataGasUsed":"0x0","extDataHash":"0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421","extraData":"0x000000000000","gasLimit":"0x131c5bc","gasUsed":"0x5208","hash":"0x8f30daa6b6074b8ad73d2d2cc134b95b72f0a4d0347972d7700d1f8b75f63d64","logsBloom":"0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000","minDelayExcess":"0x799af4","minPriceExponent":"0x0","miner":"0x0100000000000000000000000000000000000000","mixHash":"0x0000000000000000000000000000000000000000000000000000000000000000","nonce":"0x0000000000000000","number":"0x3","pChainHeight":"0x0","parentBeaconBlockRoot":"0x0000000000000000000000000000000000000000000000000000000000000000","parentHash":"0x41a0ef67607a66013f91e3cada962897250eac607aab7d227b6f642badd62f58","receiptsRoot":"0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421","settledExcess":"0x15f5","settledGasNumerator":"0xd6608","settledGasUnix":"0x6af36e6f","settledHeight":"0x1","sha3Uncles":"0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347","stateRoot":"0x3d53a68c84ad70512b2e4e578469077b6f630d3b1ed6448e9c2b23de256932f1","targetExponent":"0x18000","timestamp":"0x6af36e76","timestampMilliseconds":"0x1a1c6e77eb1","transactionsRoot":"0x593ae0700bdd5a8e0d7a8e479756a405fdd3bf4875fc0bee80bd1d5dbae3f67e"}`

func TestHeliconHeaderHash(t *testing.T) {
	var raw struct {
		Hash         common.Hash `json:"hash"`
		PChainHeight *string     `json:"pChainHeight"`
	}
	require.NoError(t, json.Unmarshal([]byte(heliconHeaderJSON), &raw))
	require.NotNil(t, raw.PChainHeight, "fixture must be an SAE header with pChainHeight")

	// Same decoding path as the coreth ethclient used by the server, with the
	// C-chain header extras registered as in cmd/server.
	require.NoError(t, evm.WithTempRegisteredLibEVMExtras(func() error {
		var header types.Header
		require.NoError(t, json.Unmarshal([]byte(heliconHeaderJSON), &header))
		require.Equal(t, raw.Hash, header.Hash())
		return nil
	}))
}
