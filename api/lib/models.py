from sqlalchemy import create_engine, Column, Integer, SmallInteger, String, DECIMAL, Enum, TIMESTAMP, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship

Base = declarative_base()

class Filter(Base):
    __tablename__ = 'filter'
    filter_id = Column(SmallInteger, primary_key=True, autoincrement=True)
    name = Column(String(20), unique=True, nullable=False, default='')

class FilterLink(Base):
    __tablename__ = 'filter_link'
    filter_id = Column(SmallInteger, ForeignKey('filter.filter_id'), primary_key=True)
    player_id = Column(SmallInteger, primary_key=True)

class Games(Base):
    __tablename__ = 'games'
    record_id = Column(Integer, primary_key=True, autoincrement=True)
    game = Column(String(12), nullable=False, default='', index=True)
    score = Column(SmallInteger)
    region = Column(String(20))
    round_ = Column(SmallInteger)
    upset = Column(SmallInteger)
    winner = Column(String(25))

class LastUpdated(Base):
    __tablename__ = 'last_updated'
    last_updated = Column(String(40), primary_key=True)

class Picks(Base):
    __tablename__ = 'picks'
    record_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(60))
    game = Column(String(25))
    winner = Column(String(25))
    player_id = Column(SmallInteger)

class PlayerInfo(Base):
    __tablename__ = 'player_info'
    player_id = Column(SmallInteger, primary_key=True, autoincrement=True)
    name = Column(String(60))
    email = Column(String(60))
    candybar = Column(String(60))
    location = Column(String(60))
    gender = Column(String(1))
    date_created = Column(TIMESTAMP)
    champion = Column(String(60))
    entry_time = Column(Integer)
    j_factor = Column(DECIMAL(4,2))
    j2_factor = Column(DECIMAL(4,2))
    how_found = Column(String(50))
    how_found_text = Column(String(50))
    years_played = Column(SmallInteger)
    man_or_chimp = Column(Enum('man', 'chimp', 'celebrity'))
    ff1 = Column(String(25))
    ff2 = Column(String(25))
    ff3 = Column(String(25))
    ff4 = Column(String(25))
    ff_man_neighbors = Column(Integer)
    ff_chimp_neighbors = Column(Integer)
    alma_mater = Column(String(25))
    past_champion = Column(String(25))

class Scores(Base):
    __tablename__ = 'scores'
    player_id = Column(Integer, ForeignKey('player_info.player_id'), primary_key=True)
    step = Column(Integer)
    score = Column(Integer)
    rank = Column(Integer)
    darwin = Column(Integer)
    name = Column(String(255))
    rtt = Column(Integer)
    man_or_chimp = Column(Enum('man', 'chimp', 'celebrity'))
    rawnumber = Column(Integer)
    combined_rank = Column(Integer)
    eliminated = Column(Enum('y', 'n'), default='n')

class SimilarityIndex(Base):
    __tablename__ = 'similarity_index'
    first_player_id = Column(Integer, primary_key=True)
    second_player_id = Column(Integer, primary_key=True)
    score = Column(Integer, nullable=False)
    similarity = Column(Integer, nullable=False)

class Teams(Base):
    __tablename__ = 'teams'
    team_id = Column(Integer, primary_key=True)
    team = Column(String(25))
    spot = Column(String(10))
    seed = Column(Integer)
    bracket = Column(SmallInteger)
    bracket_name = Column(String(10))
    url = Column(String(255))

