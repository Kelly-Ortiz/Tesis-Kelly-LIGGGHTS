from pathlib import Path
import re

INPUT_FOLDER = Path("post")
OUTPUT_FOLDER = Path("post_vtk")

OUTPUT_FOLDER.mkdir(exist_ok=True)


def natural_key(path):
    nums = re.findall(r"\d+", path.name)
    return int(nums[-1]) if nums else 0


def read_liggghts_dump(file_path):
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    timestep = None
    natoms = None
    atom_columns = None
    atom_data = []

    i = 0
    while i < len(lines):
        line = lines[i].strip()

        if line.startswith("ITEM: TIMESTEP"):
            timestep = int(lines[i + 1].strip())
            i += 2

        elif line.startswith("ITEM: NUMBER OF ATOMS"):
            natoms = int(lines[i + 1].strip())
            i += 2

        elif line.startswith("ITEM: ATOMS"):
            atom_columns = line.split()[2:]
            i += 1

            for _ in range(natoms):
                values = lines[i].split()
                atom_data.append(values)
                i += 1
        else:
            i += 1

    if atom_columns is None:
        raise ValueError(f"No se encontró ITEM: ATOMS en {file_path}")

    return timestep, atom_columns, atom_data


def get_float(row, columns, name, default=0.0):
    if name in columns:
        return float(row[columns.index(name)])
    return default


def get_int(row, columns, name, default=0):
    if name in columns:
        return int(float(row[columns.index(name)]))
    return default


def write_vtk(output_path, timestep, columns, data):
    n = len(data)

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("# vtk DataFile Version 3.0\n")
        f.write(f"LIGGGHTS particles timestep {timestep}\n")
        f.write("ASCII\n")
        f.write("DATASET POLYDATA\n")

        # Puntos
        f.write(f"POINTS {n} float\n")
        for row in data:
            x = get_float(row, columns, "x")
            y = get_float(row, columns, "y")
            z = get_float(row, columns, "z")
            f.write(f"{x} {y} {z}\n")

        # Vértices para que ParaView reconozca cada partícula como punto
        f.write(f"\nVERTICES {n} {2*n}\n")
        for idx in range(n):
            f.write(f"1 {idx}\n")

        f.write(f"\nPOINT_DATA {n}\n")

        # ID
        f.write("SCALARS id int 1\n")
        f.write("LOOKUP_TABLE default\n")
        for row in data:
            f.write(f"{get_int(row, columns, 'id')}\n")

        # Type
        f.write("\nSCALARS type int 1\n")
        f.write("LOOKUP_TABLE default\n")
        for row in data:
            f.write(f"{get_int(row, columns, 'type')}\n")

        # Radius
        f.write("\nSCALARS radius float 1\n")
        f.write("LOOKUP_TABLE default\n")
        for row in data:
            f.write(f"{get_float(row, columns, 'radius')}\n")

        # Mass, si existe
        if "mass" in columns:
            f.write("\nSCALARS mass float 1\n")
            f.write("LOOKUP_TABLE default\n")
            for row in data:
                f.write(f"{get_float(row, columns, 'mass')}\n")

        # Velocidad
        if all(col in columns for col in ["vx", "vy", "vz"]):
            f.write("\nVECTORS velocity float\n")
            for row in data:
                vx = get_float(row, columns, "vx")
                vy = get_float(row, columns, "vy")
                vz = get_float(row, columns, "vz")
                f.write(f"{vx} {vy} {vz}\n")

        # Fuerza
        if all(col in columns for col in ["fx", "fy", "fz"]):
            f.write("\nVECTORS force float\n")
            for row in data:
                fx = get_float(row, columns, "fx")
                fy = get_float(row, columns, "fy")
                fz = get_float(row, columns, "fz")
                f.write(f"{fx} {fy} {fz}\n")


def main():
    files = sorted(INPUT_FOLDER.glob("particles_*.liggghts"), key=natural_key)

    if not files:
        print("No se encontraron archivos particles_*.liggghts en la carpeta post.")
        return

    for file_path in files:
        timestep, columns, data = read_liggghts_dump(file_path)
        output_file = OUTPUT_FOLDER / f"{file_path.stem}.vtk"
        write_vtk(output_file, timestep, columns, data)
        print(f"Convertido: {file_path} -> {output_file}")

    print("\nListo. Abre en ParaView los archivos de la carpeta post_vtk.")


if __name__ == "__main__":
    main()