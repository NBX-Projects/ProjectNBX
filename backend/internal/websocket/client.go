package websocket

import (
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/projectnbx/backend/internal/models"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512 * 1024 // 512 KB
)

// Client representa uma conexão WebSocket individual de um usuário
type Client struct {
	Hub      *Hub
	Conn     *websocket.Conn
	Send     chan []byte
	UserID   string
	Username string
	ServerID string

	sendMu sync.Mutex
	closed bool
}

// SendEvent envia dados de forma thread-safe sem risco de panic em canal fechado
func (c *Client) SendEvent(data []byte) bool {
	c.sendMu.Lock()
	defer c.sendMu.Unlock()

	if c.closed {
		return false
	}

	select {
	case c.Send <- data:
		return true
	default:
		return false
	}
}

// Close fecha o canal Send e a conexão subjacente de forma atômica e segura
func (c *Client) Close() {
	c.sendMu.Lock()
	defer c.sendMu.Unlock()

	if c.closed {
		return
	}
	c.closed = true
	close(c.Send)
	if c.Conn != nil {
		_ = c.Conn.Close()
	}
}

func (c *Client) ReadPump() {
	defer func() {
		c.Hub.Unregister <- c
		c.Close()
	}()

	c.Conn.SetReadLimit(maxMessageSize)
	c.Conn.SetReadDeadline(time.Now().Add(pongWait))
	c.Conn.SetPongHandler(func(string) error {
		c.Conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("[WebSocket] Erro na conexão do usuário %s: %v", c.UserID, err)
			}
			break
		}

		// Reseta o deadline de leitura a cada mensagem recebida com sucesso
		c.Conn.SetReadDeadline(time.Now().Add(pongWait))

		var event models.WSEvent
		if err := json.Unmarshal(message, &event); err != nil {
			log.Printf("[WebSocket] Falha ao desserializar evento: %v", err)
			continue
		}

		// Processa o evento através do Hub
		c.Hub.HandleClientEvent(c, &event)
	}
}

func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			if err := c.Conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}

		case <-ticker.C:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

