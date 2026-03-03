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

    // 재입장 시 이전 room 잔존으로 꼬이는 현상 방지
    for (const r of socket.rooms) {
      if (r !== socket.id) socket.leave(r);
    }

    socket.join(roomId);
    socket.data.roomId = roomId;
    socket.data.nickname = nickname;
    socket.emit('joined_room', { roomId, ok: true });
    socket.to(roomId).emit('typing', { nickname, typing: false });
  });

  socket.on('leave_room', ({ roomId, nickname: leaveNick }) => {
    if (!roomId) return;

    const who = leaveNick || socket.data.nickname || nickname;
    io.to(roomId).emit('new_message', {
      roomId,
      nickname: 'SYSTEM',
      text: `${who}님이 퇴장하였습니다.`,
      createdAt: new Date().toISOString(),
    });

    socket.leave(roomId);
    socket.data.roomId = null;
    socket.to(roomId).emit('typing', { nickname: who, typing: false });
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
    const roomId = socket.data.roomId;
    const who = socket.data.nickname || nickname;
    if (roomId) {
      io.to(roomId).emit('new_message', {
        roomId,
        nickname: 'SYSTEM',
        text: `${who}님이 퇴장하였습니다.`,
        createdAt: new Date().toISOString(),
      });
      socket.to(roomId).emit('typing', { nickname: who, typing: false });
    }
    console.log('disconnect:', socket.id);
  });
});

const PORT = process.env.PORT || 3001;
const HOST = process.env.HOST || '0.0.0.0';
server.listen(PORT, HOST, () => {
  console.log(`socket server running on http://localhost:${PORT}`);
  console.log(`socket server LAN bind: http://${HOST}:${PORT}`);
});
