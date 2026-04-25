#!/usr/bin/env python3
import json
import os
from pathlib import Path
from urllib.error import URLError, HTTPError
from urllib.request import Request, urlopen

import chromadb
import pandas as pd
import streamlit as st

ROOT = Path('/workspace/orebit-rag-deploy/rag-system')
CHROMA_DIR = ROOT / 'chroma'
API_HEALTH_URL = 'http://127.0.0.1:3004/api/rag/health'
API_QUERY_URL = 'http://127.0.0.1:3004/api/rag/query'
VAULT_ROOT = Path('/workspace/obsidian-system/vault')
RESEARCH_ROOT = Path('/workspace/research-data')

st.set_page_config(page_title='Orebit RAG Local Dashboard', page_icon='OK', layout='wide')


def fetch_json(url, method='GET', payload=None):
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode('utf-8')
        headers['Content-Type'] = 'application/json'
    req = Request(url, data=data, headers=headers, method=method)
    with urlopen(req, timeout=10) as resp:
        return resp.status, json.loads(resp.read().decode('utf-8'))


@st.cache_data(ttl=30)
def get_api_health():
    try:
        status, body = fetch_json(API_HEALTH_URL)
        return {'ok': status == 200, 'status': status, 'body': body}
    except Exception as exc:
        return {'ok': False, 'status': None, 'body': str(exc)}


@st.cache_data(ttl=30)
def get_chroma_stats():
    if not CHROMA_DIR.exists():
        return {'exists': False, 'collections': []}
    client = chromadb.PersistentClient(path=str(CHROMA_DIR))
    cols = []
    for coll in client.list_collections():
        try:
            count = client.get_collection(coll.name).count()
        except Exception:
            count = 'unknown'
        cols.append({'name': coll.name, 'count': count})
    return {'exists': True, 'collections': cols}


def list_para_dirs():
    names = ['0. Inbox', '1. Projects', '2. Areas', '3. Resources', '4. Archive']
    return [{'name': n, 'exists': (VAULT_ROOT / n).exists()} for n in names]


def list_research_dirs():
    names = ['nala', 'orebit', 'papers-index']
    return [{'name': n, 'exists': (RESEARCH_ROOT / n).exists()} for n in names]


st.title('Orebit RAG Local Dashboard')
st.caption('Local fallback dashboard without Docker')

health = get_api_health()
chroma = get_chroma_stats()
para = list_para_dirs()
research = list_research_dirs()

c1, c2, c3, c4 = st.columns(4)
c1.metric('RAG API', 'UP' if health['ok'] else 'DOWN')
c2.metric('Chroma Dir', 'READY' if chroma['exists'] else 'MISSING')
c3.metric('PARA Folders', sum(1 for x in para if x['exists']))
c4.metric('Research Dirs', sum(1 for x in research if x['exists']))

st.subheader('API Health')
st.json(health['body'])

st.subheader('Chroma Collections')
if chroma['collections']:
    st.dataframe(pd.DataFrame(chroma['collections']), use_container_width=True)
else:
    st.info('No collections found yet.')

st.subheader('PARA Status')
st.dataframe(pd.DataFrame(para), use_container_width=True)

st.subheader('Research Status')
st.dataframe(pd.DataFrame(research), use_container_width=True)

st.subheader('Quick Query Test')
query = st.text_input('Query', value='test query')
if st.button('Run Query'):
    try:
        status, body = fetch_json(API_QUERY_URL, method='POST', payload={'query': query, 'top_k': 3})
        st.write(f'Status: {status}')
        st.json(body)
    except HTTPError as exc:
        st.error(f'HTTPError: {exc.code}')
    except URLError as exc:
        st.error(f'URLError: {exc}')
    except Exception as exc:
        st.error(str(exc))
