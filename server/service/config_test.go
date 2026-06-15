package service

import (
	"math/big"
	"testing"

	"github.com/ava-labs/coreth/params"
	"github.com/ava-labs/coreth/plugin/evm"
	"github.com/coinbase/rosetta-sdk-go/types"
	"github.com/stretchr/testify/require"

	"github.com/ava-labs/avalanche-rosetta/mapper"

	ethtypes "github.com/ava-labs/libevm/core/types"
)

func TestConfig(t *testing.T) {
	evm.RegisterAllLibEVMExtras()
	t.Run("online", func(t *testing.T) {
		cfg := Config{
			Mode:      "online",
			ChainID:   params.AvalancheMainnetChainID,
			NetworkID: &types.NetworkIdentifier{},
		}

		require.False(t, cfg.IsOfflineMode())
		require.True(t, cfg.IsOnlineMode())
	})

	t.Run("offline", func(t *testing.T) {
		cfg := Config{
			Mode:      "offline",
			ChainID:   params.AvalancheMainnetChainID,
			NetworkID: &types.NetworkIdentifier{},
		}

		require.True(t, cfg.IsOfflineMode())
		require.False(t, cfg.IsOnlineMode())
	})

	t.Run("signer", func(t *testing.T) {
		flareChainID := big.NewInt(mapper.FlareChainID)
		cfg := Config{
			ChainID: flareChainID,
		}
		require.IsType(t, ethtypes.NewCancunSigner(flareChainID), cfg.Signer())
	})
}
