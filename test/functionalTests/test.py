from dataclasses import dataclass
from enum import Enum
import glob
import os
import subprocess
from pathlib import Path
from typing import Optional

from pyshacl import validate
from rdflib import Graph


PROJECT_DIR = Path("/home/greg/PROJECTS/model2owl_meaningfy")
TEST_DIR = PROJECT_DIR / Path("test/functionalTests")
TEST_CASES_DIR = TEST_DIR / Path("testCases")
NAMESPACES_FILE = TEST_DIR / Path("model2owl-config/namespaces.xml")
OUTPUT_DIR = TEST_CASES_DIR / Path(".output")

INPUT_TEST_XMI_NAME = "test_model"  # FIXME
INPUT_TEST_XMI_FILE = f"{INPUT_TEST_XMI_NAME}.xmi"

@dataclass
class Model2owlArtefact:
    name: str
    cliCommand: str
    testShapesDirName: str
    artefactFileName: str
    testShapesDirPath: Optional[Path] = None


class Model2owlArtefacts(Enum):
    CORE = Model2owlArtefact(
        "core", "owl-core", "core-shapes", f"{INPUT_TEST_XMI_NAME}.owl"
    )
    RESTRICTIONS = Model2owlArtefact(
        "restrictions", "owl-restrictions", "restrictions-shapes", f"{INPUT_TEST_XMI_NAME}_restrictions.owl"
    )
    SHAPES = Model2owlArtefact(
        "shapes", "shacl", "shapes-shapes", f"{INPUT_TEST_XMI_NAME}_shapes.owl"
    )


def identify_affected_model2owl_artefacts(base_dir):
    target_artefacts = []

    # Check each target directory
    test_shape_dirs = [a.value.testShapesDirName for a in list(Model2owlArtefacts)]
    for a_enum in list(Model2owlArtefacts):
        a = a_enum.value
        dir_name = a.testShapesDirName
        dir_path = os.path.join(base_dir, dir_name)
        if os.path.isdir(dir_path):
            a.testShapesDirPath = dir_path
            target_artefacts.append(a)

    # Ensure at least one exists
    if not target_artefacts:
        raise FileNotFoundError("None of the expected directories exist: " + ", ".join(test_shape_dirs))

    return target_artefacts


def generate_and_test(input_xmi_file, artefacts, test_output_dir):
    for a in artefacts:
        print(f"=== Processing {a.name} artefact ...===")
        print(f"Generating {a.name} artefact ...")
        run_model2owl(input_xmi_file, test_output_dir, command=a.cliCommand)
        for test_file in get_shacl_files(a.testShapesDirPath):
            print(f"Testing {a.name} artefact with {test_file} test file ...")
            restriction_file = test_output_dir / a.artefactFileName
            print(restriction_file)
            test_validate_with_shacl(restriction_file, test_file)


# TODO: make a parametrised fixture from this
def run_model2owl(input_xmi_file, 
                  output_dir, 
                  command: str
    ):
    
    # Ensure output directory exists (optional)
    output_dir.mkdir(parents=True, exist_ok=True)

    subprocess.run(
        [
            "make", command,
            f"XMI_INPUT_FILE_PATH={input_xmi_file}",
            f"OUTPUT_FOLDER_PATH={output_dir}",
            f"NAMESPACES_USER_XML_FILE_PATH={NAMESPACES_FILE}"
        ],
        cwd=PROJECT_DIR,
        check=True
    )


def test_validate_with_shacl(data_file, shacl_shapes_file):
    conforms, report_graph, report_text = validate(
        Graph().parse(data_file, format="xml"),
        shacl_graph=Graph().parse(shacl_shapes_file, format="ttl")
    )
    assert conforms, f"SHACL validation failed:\n{report_graph.serialize()}"
    print(report_text)


def get_shacl_files(dir):
    return glob.glob(os.path.join(dir, "*.shacl.ttl"))


if __name__ == "__main__":
    # runs tests for a single test test case
    test_case_name = "association-domain_range"
    test_case_dir = TEST_CASES_DIR / test_case_name
    input_xmi_file = test_case_dir / INPUT_TEST_XMI_FILE
    test_output_dir = OUTPUT_DIR / test_case_name

    artefacts = identify_affected_model2owl_artefacts(test_case_dir)
    generate_and_test(input_xmi_file, artefacts, test_output_dir)
    