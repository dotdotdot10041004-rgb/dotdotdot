const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');

const app = express();
app.use(cors());
app.get('/', (_, res) => res.send('dot dot dot socket server ok'));

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
});

io.on('connection', (socket) => {
  const nickname = socket.handshake.query.nickname || 'guest';
  console.log('connected:', socket.id, nickname);

  socket.on('join_room', ({ roomId }) => {
    if (!roomId) return;
    socket.join(roomId);
    socket.to(roomId).emit('typing', { nickname, typing: false });
  });

  socket.on('leave_room', ({ roomId }) => {
    if (!roomId) return;
    socket.leave(roomId);
    socket.to(roomId).emit('typing', { nickname, typing: false });
  });

  socket.on('typing', ({ roomId, nickname, typing }) => {
    if (!roomId) return;
    socket.to(roomId).emit('typing', { nickname, typing: !!typing });
  });

  socket.on('send_message', (payload) => {
    const roomId = payload?.roomId;
    if (!roomId) return;

    const msg = {
      roomId,
      nickname: payload.nickname || nickname,
      text: payload.text || '',
      createdAt: payload.createdAt || new Date().toISOString(),
    };

    io.to(roomId).emit('new_message', msg);
    socket.to(roomId).emit('typing', { nickname: msg.nickname, typing: false });
  });

  socket.on('disconnect', () => {
    console.log('disconnect:', socket.id);
  });
});

const PORT = process.env.PORT || 3001;
const HOST = process.env.HOST || '0.0.0.0';
server.listen(PORT, HOST, () => {
  console.log(`socket server running on http://localhost:${PORT}`);
  console.log(`socket server LAN bind: http://${HOST}:${PORT}`);
});
