const http = require('http');
const WebSockets = require('./utilsWebSockets.js');
const GameMessages = require('./utilsGameMessages.js');
const GameLoop = require('./utilsGameLoop.js');

const port = 3000;
const ws = new WebSockets();
const gameMessages = new GameMessages(ws);
const gameLoop = new GameLoop();

const httpServer = http.createServer();
ws.init(httpServer, port);

let players = {}; 
// NUEVAS VARIABLES DE ESTADO PARA CONTROLAR EL FLUJO CORRECTAMENTE
let enCuentaAtras = false;
let partidaEnCurso = false;
let finalizandoPartida = false;
let countdownInterval = null;
let powerUpInterval = null; 

let bullets = []; 
let powerUps = []; 
let efectos = []; 

const spawnZones = [
    { x: 34, y: 29, width: 29, height: 29 }, { x: 425, y: 34, width: 29, height: 29 },
    { x: 385, y: 204, width: 29, height: 29 }, { x: 186, y: 9, width: 29, height: 29 }, 
    { x: 82, y: 186, width: 29, height: 29 }
];

const walls = [
    {x: 0, y: 0, width: 512, height: 4}, {x: 0, y: 250, width: 512, height: 4}, 
    {x: 508, y: 6, width: 4, height: 244}, {x: 0, y: 6, width: 4, height: 244}, 
    {x: 176, y: 80, width: 80, height: 4}, {x: 288, y: 96, width: 48, height: 4},
    {x: 316, y: 59, width: 51, height: 4}, {x: 400, y: 16, width: 16, height: 4}, 
    {x: 64, y: 16, width: 16, height: 4}, {x: 176, y: 112, width: 32, height: 4}, 
    {x: 64, y: 171, width: 64, height: 4}, {x: 48, y: 96, width: 64, height: 4},
    {x: 176, y: 43, width: 64, height: 4}, {x: 128, y: 176, width: 64, height: 4}, 
    {x: 304, y: 176, width: 32, height: 4}, {x: 384, y: 128, width: 32, height: 4}, 
    {x: 412, y: 133, width: 4, height: 22}, {x: 464, y: 32, width: 4, height: 32},
    {x: 172, y: 5, width: 4, height: 42}, {x: 124, y: 176, width: 4, height: 48}, 
    {x: 76, y: 21, width: 4, height: 75}, {x: 140, y: 96, width: 4, height: 79}, 
    {x: 332, y: 101, width: 4, height: 75}, {x: 412, y: 21, width: 4, height: 75},
    {x: 444, y: 100, width: 4, height: 92}, {x: 252, y: 85, width: 4, height: 90}, 
    {x: 384, y: 133, width: 30, height: 22}, {x: 204, y: 117, width: 4, height: 22}, 
    {x: 176, y: 117, width: 30, height: 22}, {x: 316, y: 49, width: 4, height: 10},
    {x: 368, y: 197, width: 4, height: 10}, {x: 384, y: 155, width: 32, height: 4}, 
    {x: 176, y: 139, width: 32, height: 4}, {x: 368, y: 96, width: 80, height: 4}, 
    {x: 368, y: 192, width: 80, height: 4}, {x: 176, y: 219, width: 160, height: 4}
];

const TANK_W = 150 * 0.075, TANK_H = 200 * 0.075;   
const ANCHOR_X = 0.5027, ANCHOR_Y = 0.3348;
const TANK_RADIUS = 7.0; 
const ITEM_RADIUS = 6.0; 

function esZonaValidaParaCaja(x, y) {
    for (let w of walls) {
        if (x + ITEM_RADIUS > w.x && x - ITEM_RADIUS < w.x + w.width && 
            y + ITEM_RADIUS > w.y && y - ITEM_RADIUS < w.y + w.height) return false;
    }
    for (let s of spawnZones) {
        if (x + ITEM_RADIUS > s.x && x - ITEM_RADIUS < s.x + s.width && 
            y + ITEM_RADIUS > s.y && y - ITEM_RADIUS < s.y + s.height) return false;
    }
    return true;
}

function generarPowerUp() {
    if (powerUps.length >= 4) return; 
    let valido = false, rx = 0, ry = 0, intentos = 0;
    while (!valido && intentos < 50) {
        rx = 20 + Math.random() * 470; 
        ry = 20 + Math.random() * 210; 
        valido = esZonaValidaParaCaja(rx, ry);
        intentos++;
    }
    if (valido) powerUps.push({ id: Math.random().toString(36).substr(2, 9), x: rx, y: ry });
}

function getTankAABB(x, y, angulo) {
    const corners = [
        { cx: -TANK_W * ANCHOR_X, cy: -TANK_H * ANCHOR_Y },                   
        { cx: TANK_W * (1 - ANCHOR_X), cy: -TANK_H * ANCHOR_Y },              
        { cx: TANK_W * (1 - ANCHOR_X), cy: TANK_H * (1 - ANCHOR_Y) },         
        { cx: -TANK_W * ANCHOR_X, cy: TANK_H * (1 - ANCHOR_Y) }               
    ];
    let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
    const cosA = Math.cos(angulo), sinA = Math.sin(angulo);
    for (let c of corners) {
        let rotX = c.cx * cosA - c.cy * sinA, rotY = c.cx * sinA + c.cy * cosA;
        if (x + rotX < minX) minX = x + rotX;
        if (x + rotX > maxX) maxX = x + rotX;
        if (y + rotY < minY) minY = y + rotY;
        if (y + rotY > maxY) maxY = y + rotY;
    }
    return { left: minX, right: maxX, top: minY, bottom: maxY };
}

function colisionaConMuro(aabb) {
    for (let w of walls) {
        if (aabb.left < w.x + w.width && aabb.right > w.x && aabb.top < w.y + w.height && aabb.bottom > w.y) return true;
    }
    return false;
}

function colisionaConTanques(miId, miAABB) {
    for (let id in players) {
        if (id !== miId && players[id].hp > 0 && !players[id].isDead) { 
            let otroAABB = getTankAABB(players[id].x, players[id].y, players[id].angulo);
            if (miAABB.left < otroAABB.right && miAABB.right > otroAABB.left && miAABB.top < otroAABB.bottom && miAABB.bottom > otroAABB.top) return true;
        }
    }
    return false;
}

function colisionaConCaja(miAABB) {
    for (let p of powerUps) {
        if (miAABB.left < p.x + ITEM_RADIUS && miAABB.right > p.x - ITEM_RADIUS && 
            miAABB.top < p.y + ITEM_RADIUS && miAABB.bottom > p.y - ITEM_RADIUS) return true;
    }
    return false;
}

function broadcast(messageObj) {
    const msgString = JSON.stringify(messageObj);
    ws.forEachClient((socket, id) => { gameMessages.enqueueReliable(socket, id, msgString); });
}

function broadcastPlayerList() {
    broadcast({ type: 'player_list', players: Object.values(players).map(p => p.name) });
}

function getCleanPlayersData() {
    let cleanData = {};
    for (let id in players) cleanData[id] = { 
        id: id, name: players[id].name, x: players[id].x, y: players[id].y, 
        angulo: players[id].angulo, hp: players[id].hp 
    };
    return cleanData;
}

// NUEVO: Lógica independiente para iniciar la cuenta atrás en la sala de espera
function iniciarCuentaAtras() {
    enCuentaAtras = true;
    let countdownValue = 30; // 60 SEGUNDOS COMO PEDISTE
    broadcast({ type: 'countdown', value: countdownValue });
    
    countdownInterval = setInterval(() => {
        countdownValue--;
        if (countdownValue > 0) {
            broadcast({ type: 'countdown', value: countdownValue });
        } else {
            // FIN DE LA CUENTA ATRÁS: EMPIEZA LA PARTIDA
            clearInterval(countdownInterval);
            countdownInterval = null;
            enCuentaAtras = false;
            partidaEnCurso = true;
            
            let i = 0;
            bullets = []; powerUps = []; efectos = [];
            for (let pid in players) {
                players[pid].x = spawnZones[i % spawnZones.length].x + 14; 
                players[pid].y = spawnZones[i % spawnZones.length].y + 14;
                players[pid].angulo = 0.0;
                players[pid].hp = 3; 
                players[pid].isDead = false; 
                players[pid].cooldown = 0;
                players[pid].ammoType = 'basic';
                players[pid].ammoCount = 0;
                i++;
            }
            powerUpInterval = setInterval(generarPowerUp, 30000);
            broadcast({ type: 'start_game', estadoPartida: getCleanPlayersData() });
        }
    }, 1000);
}

ws.onConnection = (socket, id) => { gameMessages.addClient(id); };

ws.onMessage = (socket, id, msg) => {
    try {
        const data = JSON.parse(msg);
        if (data.type === 'register') {
            players[id] = { 
                id: id, name: data.playerName, socket: socket, x: 0, y: 0, angulo: 0.0, hp: 3, cooldown: 0, 
                isDead: false, 
                inputs: { w: false, a: false, s: false, d: false, space: false },
                ammoType: 'basic', ammoCount: 0 
            };
            broadcastPlayerList();

            // Si hay 2 o más jugadores y la cuenta atrás NO ha empezado, la empezamos.
            // Si ya hay una cuenta en marcha (entró el 3ro), no hacemos nada para no reiniciarla.
            if (Object.keys(players).length >= 2 && !enCuentaAtras && !partidaEnCurso) {
                iniciarCuentaAtras();
            }
        } 
        else if (data.type === 'input') {
            if (players[id]) players[id].inputs = data.keys;
        }
    } catch (e) {}
};

ws.onClose = (socket, id) => {
    gameMessages.removeClient(id);
    if (players[id]) { delete players[id]; broadcastPlayerList(); }
    
    // Si la gente se desconecta y queda menos de 2 personas:
    if (Object.keys(players).length < 2) {
        if (enCuentaAtras) {
            // Cancelamos la cuenta atrás en la sala de espera
            clearInterval(countdownInterval);
            countdownInterval = null;
            enCuentaAtras = false;
            broadcast({ type: 'countdown_cancelled' });
        }
        // Si la partida está en curso, la lógica del loop detectará que solo queda 1 vivo y la acabará automáticamente
    }
};

gameLoop.run = (fps) => { 
    if (partidaEnCurso) {
        const VELOCIDAD = 45 / fps;
        const VEL_ROTACION = 2.5 / fps; 
        const VEL_BALA_NORMAL = 120 / fps; 
        const VEL_BALA_HEAVY = 75 / fps; 

        // --- LÓGICA DE CONDICIÓN DE FIN DE PARTIDA ---
        if (!finalizandoPartida) {
            let jugadoresVivos = 0;
            let posibleGanador = null;

            for (let pid in players) {
                if (players[pid].hp > 0 && !players[pid].isDead) {
                    jugadoresVivos++;
                    posibleGanador = pid;
                }
            }

            // Si solo queda 1 jugador (o todos mueren a la vez por fuego amigo)
            if (jugadoresVivos <= 1 && Object.keys(players).length > 0) {
                finalizandoPartida = true;
                if (powerUpInterval) { clearInterval(powerUpInterval); powerUpInterval = null; }

                // Esperamos 1.5 segundos para que se termine de ver la animación de la explosión
                setTimeout(() => {
                    partidaEnCurso = false;
                    finalizandoPartida = false;
                    
                    // Avisamos a los clientes de quién ha ganado para mostrar la pantalla
                    broadcast({ type: 'end_game', winner: posibleGanador });

                    // Reseteamos las estadísticas de todos para la próxima ronda
                    for (let pid in players) {
                        players[pid].hp = 3;
                        players[pid].isDead = false;
                        players[pid].ammoType = 'basic';
                        players[pid].ammoCount = 0;
                    }

                    // Si hay suficientes jugadores en la sala, empieza la cuenta de 60s sola
                    if (Object.keys(players).length >= 2) {
                        iniciarCuentaAtras();
                    }
                }, 1500); 
            }
        }

        // --- FÍSICA Y MOVIMIENTO (Solo si no están muertos) ---
        for (let id in players) {
            let p = players[id];
            if (p.hp <= 0) continue; 

            if (p.cooldown > 0) p.cooldown--; 
            if (p.inputs.a) p.angulo -= VEL_ROTACION;
            if (p.inputs.d) p.angulo += VEL_ROTACION;

            let frenteX = Math.cos(p.angulo + Math.PI / 2), frenteY = Math.sin(p.angulo + Math.PI / 2);
            let nextX = p.x, nextY = p.y;

            if (p.inputs.w) { nextX += frenteX * VELOCIDAD; nextY += frenteY * VELOCIDAD; }
            if (p.inputs.s) { nextX -= frenteX * VELOCIDAD; nextY -= frenteY * VELOCIDAD; }

            let aabbX = getTankAABB(nextX, p.y, p.angulo);
            if (!colisionaConMuro(aabbX) && !colisionaConTanques(id, aabbX) && !colisionaConCaja(aabbX)) p.x = nextX; 

            let aabbY = getTankAABB(p.x, nextY, p.angulo);
            if (!colisionaConMuro(aabbY) && !colisionaConTanques(id, aabbY) && !colisionaConCaja(aabbY)) p.y = nextY; 

            if (p.inputs.space && p.cooldown <= 0) {
                let tipoBalaFinal = p.ammoType;
                
                bullets.push({ 
                    id: Math.random().toString(36).substr(2, 9), 
                    owner: id, 
                    type: tipoBalaFinal, 
                    bounces: tipoBalaFinal === 'ricochet' ? 4 : 0,
                    x: p.x + frenteX * 8, 
                    y: p.y + frenteY * 8, 
                    vx: frenteX, vy: frenteY 
                });

                if (p.ammoType !== 'basic') {
                    p.ammoCount--;
                    if (p.ammoCount <= 0) {
                        p.ammoType = 'basic';
                    }
                }
                p.cooldown = 30; 
            }
        }

        // --- BALAS ---
        for (let i = bullets.length - 1; i >= 0; i--) {
            let b = bullets[i];
            let prevX = b.x;
            let prevY = b.y;

            let currSpeed = (b.type === 'heavy') ? VEL_BALA_HEAVY : VEL_BALA_NORMAL;
            
            b.x += b.vx * currSpeed;
            b.y += b.vy * currSpeed;
            
            let hit = false;
            
            let hitWall = null;
            for (let w of walls) {
                if (b.x >= w.x && b.x <= w.x + w.width && b.y >= w.y && b.y <= w.y + w.height) { 
                    hitWall = w; break; 
                }
            }

            if (hitWall) {
                if (b.type === 'ricochet' && b.bounces > 0) {
                    b.bounces--;
                    let hitHorizontal = (prevX < hitWall.x || prevX > hitWall.x + hitWall.width);
                    let hitVertical = (prevY < hitWall.y || prevY > hitWall.y + hitWall.height);
                    
                    if (hitHorizontal && !hitVertical) b.vx *= -1;
                    else if (hitVertical && !hitHorizontal) b.vy *= -1;
                    else { b.vx *= -1; b.vy *= -1; } 
                    
                    b.x = prevX; b.y = prevY;
                } else {
                    hit = true; 
                }
            }

            if (!hit) {
                for (let j = powerUps.length - 1; j >= 0; j--) {
                    let pu = powerUps[j];
                    let dx = b.x - pu.x, dy = b.y - pu.y;
                    if (Math.sqrt(dx * dx + dy * dy) < ITEM_RADIUS + 2) {
                        hit = true;
                        const premios = ['health', 'heavy', 'ricochet'];
                        const premioElegido = premios[Math.floor(Math.random() * premios.length)];
                        
                        if (players[b.owner]) {
                            if (premioElegido === 'health') {
                                players[b.owner].hp = Math.min(3, players[b.owner].hp + 1);
                            } else {
                                players[b.owner].ammoType = premioElegido;
                                players[b.owner].ammoCount = 3; 
                            }
                        }
                        efectos.push({ x: pu.x, y: pu.y, type: premioElegido, timer: 60 }); 
                        powerUps.splice(j, 1); 
                        break;
                    }
                }
            }

            if (!hit) {
                for (let pid in players) {
                    if (players[pid].hp > 0 && !players[pid].isDead) { 
                        let puedeDarleAlDuenyo = (b.type === 'ricochet' && b.bounces < 4);

                        if (pid !== b.owner || puedeDarleAlDuenyo) {
                            let tp = players[pid];
                            let dx = b.x - tp.x, dy = b.y - tp.y;
                            if (Math.sqrt(dx * dx + dy * dy) < TANK_RADIUS) {
                                hit = true;
                                let damage = (b.type === 'heavy') ? 2 : 1;
                                players[pid].hp -= damage; 
                                
                                if (players[pid].hp <= 0) {
                                    players[pid].hp = 0;
                                    players[pid].isDead = true;
                                    efectos.push({ x: tp.x, y: tp.y, type: 'dead', timer: 30 });
                                }
                                break;
                            }
                        }
                    }
                }
            }

            if (hit) bullets.splice(i, 1);
        }

        for (let i = efectos.length - 1; i >= 0; i--) {
            efectos[i].timer--;
            if (efectos[i].type !== 'dead') efectos[i].y -= 0.2; 
            if (efectos[i].timer <= 0) efectos.splice(i, 1);
        }

        const msg = JSON.stringify({ 
            type: 'update_state', 
            estadoPartida: getCleanPlayersData(),
            balas: bullets,
            powerUps: powerUps,
            efectos: efectos 
        });
        
        ws.forEachClient((socket, id) => { gameMessages.enqueueReplaceable(socket, id, 'gameStateUpdate', msg); });
    }
    gameMessages.flushAll(); 
};

httpServer.listen(port, () => { console.log(`Servidor base en el puerto ${port}`); gameLoop.start(); });