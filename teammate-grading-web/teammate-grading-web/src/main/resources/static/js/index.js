const form = document.getElementById('gradingForm');
const inputArea = document.getElementById('inputArea');
const roleRadios = document.querySelectorAll('input[name="role"]');
const resultArea = document.getElementById('resultArea')

let role = 'developer';

function renderInputArea() {
    if (role === 'developer') {
        inputArea.innerHTML = `
            <label for="githubUsername">GitHub 이름</label>
            <input
                type="text"
                id="githubUsername"
                name="githubUsername"
                placeholder="예: gasic37200"
                required
            >
        `;
        return;
    }

    if (role === 'designer') {
        inputArea.innerHTML = `
            <label for="portfolioImages">포트폴리오 이미지</label>
            <input
                type="file"
                id="portfolioImages"
                name="portfolioImages"
                accept="image/*"
                multiple
            >
            <ul id="fileList"></ul>
        `;
        return;
    }

    if (role === 'planner') {
        inputArea.innerHTML = `
            <label for="planningPDF">기획서 파일</label>
            <input
                type="file"
                id="planningPDF"
                name="planningPDF"
                accept="application/pdf,.pdf"
                required
            >
        `;
    }
}

renderInputArea()

roleRadios.forEach((radio) => {
    radio.addEventListener('change', (event) => {
        role = event.target.value;
        renderInputArea();
    });
});

form.addEventListener('submit', async (event) => {
    event.preventDefault();
    await requestGrading();
});

async function requestGrading() {
    const formData = new FormData(form);

    formData.delete('portfolioImages');

    selectedPortfolioImages.forEach((file) => {
        formData.append('portfolioImages', file);
    });

    try {
        const response = await fetch('/api/grading', {
            method: 'POST',
            body: formData
        });

        if (!response.ok) {
            throw new Error('평가 요청을 처리하지 못했습니다.');
        }

        const result = await response.json();
        renderResult(result);
    } catch (error) {
        resultArea.textContent = error.message || '평가 요청 중 오류가 발생했습니다.';
    }
}
function renderResult(result) {
    const resultArea = document.getElementById('resultArea');

    resultArea.innerHTML = `
        <section>
            <h2>평가 결과</h2>
            <p><strong>직군:</strong> ${escapeHtml(result.role)}</p>
            <p><strong>최종 점수:</strong> ${escapeHtml(result.final_score ?? result.finalScore)}</p>
            <p><strong>등급:</strong> ${escapeHtml(result.grade)}</p>

            <h3>세부 평가</h3>
            ${renderDetailResult(result.result)}
        </section>
    `;
}

function renderDetailResult(resultMap) {
    if (!resultMap) {
        return '<p>세부 평가 결과가 없습니다.</p>';
    }

    return Object.entries(resultMap)
        .map(([key, value]) => {
            if (typeof value === 'object') {
                return `
                    <div>
                        <h4>${escapeHtml(key)}</h4>
                        <p>점수: ${escapeHtml(value.score)}</p>
                        <p>이유: ${escapeHtml(value.reason)}</p>
                    </div>
                `;
            }

            return `
                <div>
                    <h4>${escapeHtml(key)}</h4>
                    <p>${escapeHtml(value)}</p>
                </div>
            `;
        })
        .join('');
}

function escapeHtml(value) {
    return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

let selectedPortfolioImages = [];

document.addEventListener('change', (event) => {
    if (event.target.id !== 'portfolioImages') {
        return;
    }

    const newFile = Array.from(event.target.files);

    selectedPortfolioImages = [
        ...selectedPortfolioImages,
        ...newFile
    ];

    renderFileList()

    event.target.value = ''
});

function renderFileList() {
    const fileList = document.getElementById('fileList');

    if (!fileList) {
        return
    }

    fileList.innerHTML = '';

    selectedPortfolioImages.forEach((file, index) => {
        const li = document.createElement('li');

        const deleteButton = document.createElement('button');
        deleteButton.type = 'button';
        deleteButton.textContent = 'X';

        deleteButton.addEventListener('click', () => {
            selectedPortfolioImages.splice(index, 1);
            renderFileList();
        });

        const fileName = document.createElement('span');
        fileName.textContent = `${index + 1}. ${file.name}`;

        li.appendChild(deleteButton);
        li.appendChild(fileName);
        fileList.appendChild(li);
    });
}
