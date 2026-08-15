package main

import (
	"context"
	"strings"
	"testing"

	"github.com/nezhahq/agent/model"
	pb "github.com/nezhahq/agent/proto"
)

func TestHardenedAgentRejectsRemovedCapabilities(t *testing.T) {
	removed := []int32{
		model.TaskTypeCommand,
		model.TaskTypeTerminal,
		model.TaskTypeTerminalGRPC,
		model.TaskTypeFM,
		model.TaskTypeExec,
		model.TaskTypeFsList,
		model.TaskTypeFsRead,
		model.TaskTypeFsWrite,
		model.TaskTypeFsDelete,
		model.TaskTypeFsTransfer,
	}

	for _, taskType := range removed {
		t.Run("type-"+string(rune(taskType)), func(t *testing.T) {
			result := doTaskWithSnapshot(context.Background(), &model.AgentConfig{}, &pb.Task{Id: 1, Type: uint64(taskType)})
			if result == nil {
				t.Fatal("removed capability must return an explicit rejection result")
			}
			if result.GetSuccessful() {
				t.Fatal("removed capability must never report success")
			}
			if !strings.Contains(result.GetData(), "does not support") {
				t.Fatalf("unexpected rejection response: %q", result.GetData())
			}
		})
	}
}
