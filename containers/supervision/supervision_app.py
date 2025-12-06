#!/usr/bin/env python3
"""
Application de supervision des logs du pare-feu
Affiche les logs en temps réel avec analyse visuelle
"""

from flask import Flask, render_template, jsonify, request
import os
import glob
import re
from datetime import datetime
from collections import defaultdict
import json

app = Flask(__name__)

# Chemin vers les logs du firewall (monté depuis logcollector)
LOG_DIR = "/mnt/logs/firewall"

def parse_log_line(line):
    """Parse une ligne de log UFW"""
    if not line.strip():
        return None
    
    # Format typique: Dec  6 18:30:15 firewall kernel: [UFW BLOCK] IN=eth0 OUT= MAC=... SRC=192.168.1.100 DST=192.168.1.1 LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=12345 DF PROTO=TCP SPT=12345 DPT=22 WINDOW=29200 RES=0x00 SYN URGP=0
    log_entry = {
        'timestamp': None,
        'action': None,
        'src_ip': None,
        'dst_ip': None,
        'protocol': None,
        'sport': None,
        'dport': None,
        'raw': line
    }
    
    # Extraire l'action UFW
    if '[UFW BLOCK]' in line:
        log_entry['action'] = 'BLOCK'
    elif '[UFW ALLOW]' in line:
        log_entry['action'] = 'ALLOW'
    elif '[UFW LIMIT]' in line:
        log_entry['action'] = 'LIMIT'
    
    # Extraire IP source
    src_match = re.search(r'SRC=(\d+\.\d+\.\d+\.\d+)', line)
    if src_match:
        log_entry['src_ip'] = src_match.group(1)
    
    # Extraire IP destination
    dst_match = re.search(r'DST=(\d+\.\d+\.\d+\.\d+)', line)
    if dst_match:
        log_entry['dst_ip'] = dst_match.group(1)
    
    # Extraire protocole
    proto_match = re.search(r'PROTO=(\w+)', line)
    if proto_match:
        log_entry['protocol'] = proto_match.group(1)
    
    # Extraire port source
    sport_match = re.search(r'SPT=(\d+)', line)
    if sport_match:
        log_entry['sport'] = sport_match.group(1)
    
    # Extraire port destination
    dport_match = re.search(r'DPT=(\d+)', line)
    if dport_match:
        log_entry['dport'] = dport_match.group(1)
    
    # Extraire timestamp (format syslog)
    time_match = re.search(r'(\w+\s+\d+\s+\d+:\d+:\d+)', line)
    if time_match:
        try:
            log_entry['timestamp'] = time_match.group(1)
        except:
            pass
    
    return log_entry

def get_recent_logs(limit=1000):
    """Récupère les logs récents"""
    logs = []
    
    if not os.path.exists(LOG_DIR):
        return logs
    
    # Lire tous les fichiers de log
    log_files = glob.glob(os.path.join(LOG_DIR, "*.log"))
    log_files.sort(reverse=True)  # Plus récents en premier
    
    for log_file in log_files[:5]:  # Limiter aux 5 fichiers les plus récents
        try:
            with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
                for line in lines[-limit:]:  # Dernières lignes
                    parsed = parse_log_line(line)
                    if parsed:
                        logs.append(parsed)
        except Exception as e:
            print(f"Erreur lecture {log_file}: {e}")
    
    # Trier par timestamp (plus récent en premier)
    logs.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
    return logs[:limit]

def get_statistics():
    """Calcule les statistiques des logs"""
    logs = get_recent_logs(5000)
    
    stats = {
        'total': len(logs),
        'by_action': defaultdict(int),
        'by_src_ip': defaultdict(int),
        'by_dport': defaultdict(int),
        'by_protocol': defaultdict(int),
        'blocked_attempts': 0,
        'allowed_connections': 0
    }
    
    for log in logs:
        if log.get('action'):
            stats['by_action'][log['action']] += 1
            if log['action'] == 'BLOCK':
                stats['blocked_attempts'] += 1
            elif log['action'] == 'ALLOW':
                stats['allowed_connections'] += 1
        
        if log.get('src_ip'):
            stats['by_src_ip'][log['src_ip']] += 1
        
        if log.get('dport'):
            stats['by_dport'][log['dport']] += 1
        
        if log.get('protocol'):
            stats['by_protocol'][log['protocol']] += 1
    
    return stats

@app.route('/')
def index():
    """Page principale avec tableau de bord"""
    return render_template('dashboard.html')

@app.route('/api/logs')
def api_logs():
    """API pour récupérer les logs"""
    limit = int(request.args.get('limit', 100))
    logs = get_recent_logs(limit)
    return jsonify(logs)

@app.route('/api/stats')
def api_stats():
    """API pour récupérer les statistiques"""
    stats = get_statistics()
    # Convertir defaultdict en dict pour JSON
    return jsonify({
        'total': stats['total'],
        'by_action': dict(stats['by_action']),
        'by_src_ip': dict(stats['by_src_ip']),
        'by_dport': dict(stats['by_dport']),
        'by_protocol': dict(stats['by_protocol']),
        'blocked_attempts': stats['blocked_attempts'],
        'allowed_connections': stats['allowed_connections']
    })

@app.route('/api/recent')
def api_recent():
    """API pour les logs récents (dernières 50 lignes)"""
    logs = get_recent_logs(50)
    return jsonify(logs)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

